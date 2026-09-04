package com.gridmeter.api.reading;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Closes the timing half of docs/resilience-scope.md's circuit-breaker work: unit tests
 * ({@link ReadingServiceTest}) already prove an open breaker throws {@code
 * CallNotPermittedException} without calling the real dependency, but that's an internal
 * behavior, not what a real HTTP caller actually experiences. This asserts wall-clock time of
 * the HTTP call itself, matching this project's own standing distinction between an internal
 * mechanism's behavior and what's actually observable from outside (App RTO vs. Infra RTO,
 * docs/postgres-ha-scope.md's Stage 7 re-verification) -- the point of a circuit breaker is a
 * caller-visible guarantee, not just an internal state machine transition.
 *
 * <p>Both breakers get this assertion independently, not just one -- the same "don't assume
 * both behave identically because one was tested" discipline this project has applied
 * throughout the HA work (redis-ha-scope.md, postgres-ha-scope.md, testing-strategy-ha-
 * supplement.md all found real per-dependency differences that a single representative test
 * would have missed).
 *
 * <p>A dedicated per-class Testcontainers set (not {@link
 * com.gridmeter.api.support.ComponentTestSupport}'s shared singleton), same reasoning as {@link
 * PostgresUnavailableComponentTest} -- both tests here genuinely stop a real dependency
 * mid-test.
 *
 * <p><b>The breaker/Hikari/Kafka property overrides below are test-speed tunables only, not a
 * claim about production-equivalent thresholds.</b> They exist purely to reach the breakers'
 * OPEN state in a few seconds instead of the real ~30s+ this test would otherwise cost against
 * application.yml's actual configured values (10-call sliding window, 5s Hikari timeout, 60s
 * Kafka max.block.ms) -- the exact real thresholds are already covered where they matter, in
 * {@link ReadingServiceTest}'s unit tests. Nothing here should be read back as "these are the
 * real numbers."
 */
@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
// Testcontainers doesn't guarantee a container keeps the same mapped host port across a
// stop()/start() cycle on the same instance, but the HikariCP DataSource bean built at context
// startup holds whatever JDBC URL @DynamicPropertySource resolved to at THAT time -- it never
// re-queries the property source on reconnect. Without this, a real port change after
// postgres.start() in the first test method leaves every later test in this class permanently
// unable to reach Postgres (confirmed directly: the Kafka test's own login call, unrelated to
// Postgres, failed with 401 once run after the Postgres test in the same shared context -- login
// needs a real DB read too). Forces a fresh context (and therefore a freshly-bound DataSource)
// after every test method, not just the ones that stop a container, since either test running
// second would otherwise inherit the first one's now-possibly-stale connections regardless of
// which dependency it stopped.
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class ReadingIngestCircuitBreakerLatencyComponentTest {

    private static final Logger log =
            LoggerFactory.getLogger(ReadingIngestCircuitBreakerLatencyComponentTest.class);

    // Well under a second (the actual bound this project cares about -- the old undeclared-
    // default hang behavior this breaker exists to prevent), but not pinned to the ~30ms this
    // project's own live measurement showed either -- that number was against the real Docker
    // Compose stack with no test-harness overhead; this leaves headroom for RestAssured/JVM
    // warm-up cost on top of the breaker's own near-instant permission check, while still tight
    // enough to catch a real regression back toward multi-second HikariCP/Kafka client timeouts.
    private static final long FAIL_FAST_CEILING_MS = 200;

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgres:18.4"))
            .withDatabaseName("gridmeter")
            .withUsername("gridmeter")
            .withPassword("gridmeter");

    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("apache/kafka:4.3.1"));

    @Container
    static GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:8.10"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
        registry.add("grid-meter.kafka.readings-topic-replicas", () -> "1");
        registry.add("grid-meter.kafka.readings-topic-min-insync-replicas", () -> "1");
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", () -> redis.getMappedPort(6379));

        // Test-speed tunables only -- see this class's own Javadoc. None of the values below are
        // production's real configured thresholds (see application.yml for those); they exist
        // solely to reach each breaker's OPEN state in a few seconds for this test's own purposes.
        //
        // Small, deterministic breaker windows for BOTH instances -- production's real 10-call
        // window (application.yml) would need many real failing calls before opening, each one
        // still costing real HikariCP/Kafka-client timeout time while CLOSED. 2 keeps this test
        // fast without changing what's actually under test (the breaker's own OPEN-state
        // behavior, not how many calls it takes to get there -- ReadingServiceTest's unit tests
        // already cover the exact threshold-crossing logic in detail).
        for (String instance : new String[] {"postgres-existence-check", "kafka-publish"}) {
            registry.add("resilience4j.circuitbreaker.instances." + instance + ".sliding-window-size", () -> "2");
            registry.add("resilience4j.circuitbreaker.instances." + instance + ".minimum-number-of-calls", () -> "2");
        }
        // Bounds each individual still-CLOSED failing call's own cost, not the breaker's
        // behavior -- without this, HikariCP's real 5s connection-timeout (application.yml)
        // alone would cost the 2 calls needed to open the Postgres breaker up to ~30s (3
        // @Retryable attempts x 5s each, per call).
        registry.add("spring.datasource.hikari.connection-timeout", () -> "500");
        // Same idea for Kafka -- bounds how long a still-CLOSED failing send() can block on a
        // metadata fetch before this test's own 2-call window is satisfied.
        registry.add("spring.kafka.producer.properties.max.block.ms", () -> "2000");
    }

    @LocalServerPort
    private int port;

    @Autowired
    private CircuitBreakerRegistry circuitBreakerRegistry;

    private String token;

    @BeforeEach
    void setUp() {
        RestAssured.baseURI = "http://localhost:" + port;
        RestAssured.basePath = "/api/v1";
        token = given()
                .contentType(ContentType.JSON)
                .body("""
                        {"username":"demo","password":"GridMeter!Demo2026"}""")
                .when()
                .post("/auth/login")
                .then()
                .statusCode(200)
                .extract().path("accessToken");
        // Both breakers reset to CLOSED before every test -- @SpringBootTest caches and shares
        // the application context (and therefore the same CircuitBreakerRegistry singleton)
        // across test methods in this class, and JUnit doesn't guarantee method execution
        // order, so without this a breaker left OPEN by one test could silently short-circuit
        // the next one before it ever reaches the dependency it means to test.
        circuitBreakerRegistry.circuitBreaker("postgres-existence-check").reset();
        circuitBreakerRegistry.circuitBreaker("kafka-publish").reset();
    }

    private Response postReading(UUID meterId) {
        return given()
                .header("Authorization", "Bearer " + token)
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .contentType(ContentType.JSON)
                .body("""
                        {"meterId":"%s","readingTimestamp":"%s","value":1.0}
                        """.formatted(meterId, Instant.now()))
                .when()
                .post("/readings");
    }

    @Test
    void postgresBreakerOpen_httpCallFailsFastWellUnderOneSecond() {
        // Never needs to actually exist -- postgres-existence-check wraps existsById() itself,
        // called before any existence result is even checked.
        UUID meterId = UUID.randomUUID();

        postgres.stop();
        try {
            // Drive to OPEN: minimum-number-of-calls=2 (overridden above), both calls fail since
            // Postgres is genuinely down.
            for (int i = 0; i < 2; i++) {
                postReading(meterId);
            }

            // The actual assertion this test exists for: wall-clock time of the HTTP call
            // itself, not an internal breaker metric like CircuitBreaker.getMetrics() or the
            // CallNotPermittedException throw time in isolation -- this is what a real caller
            // waiting on the socket actually experiences.
            long startNanos = System.nanoTime();
            Response response = postReading(meterId);
            long elapsedMs = (System.nanoTime() - startNanos) / 1_000_000;

            log.info("postgres-existence-check breaker OPEN: HTTP call took {}ms (ceiling {}ms)",
                    elapsedMs, FAIL_FAST_CEILING_MS);
            assertThat(response.statusCode()).isEqualTo(503);
            assertThat(elapsedMs).isLessThan(FAIL_FAST_CEILING_MS);
        } finally {
            postgres.start();
        }
    }

    @Test
    void kafkaBreakerOpen_httpCallFailsFastWellUnderOneSecond() {
        // Needs a REAL, existing meter -- the Postgres breaker gates before the Kafka breaker in
        // ingest()'s own call order, so existsById() must genuinely succeed to ever reach the
        // Kafka publish call this test means to exercise.
        String meterId = given()
                .header("Authorization", "Bearer " + token)
                .contentType(ContentType.JSON)
                .body("""
                        {"serialNumber":"CB-LATENCY-TEST","location":"test","status":"ACTIVE","installedAt":"2026-01-01T00:00:00Z"}
                        """)
                .when()
                .post("/meters")
                .then()
                .statusCode(201)
                .extract().path("id");

        kafka.stop();
        try {
            for (int i = 0; i < 2; i++) {
                postReading(UUID.fromString(meterId));
            }

            long startNanos = System.nanoTime();
            Response response = postReading(UUID.fromString(meterId));
            long elapsedMs = (System.nanoTime() - startNanos) / 1_000_000;

            log.info("kafka-publish breaker OPEN: HTTP call took {}ms (ceiling {}ms)",
                    elapsedMs, FAIL_FAST_CEILING_MS);
            assertThat(response.statusCode()).isEqualTo(503);
            assertThat(elapsedMs).isLessThan(FAIL_FAST_CEILING_MS);
        } finally {
            kafka.start();
        }
    }
}
