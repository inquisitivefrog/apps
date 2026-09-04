package com.gridmeter.api.common;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
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
 * Regression test for a real bug found 2026-09-04 while live-testing
 * {@code ReadingService.ingest()}'s new circuit breakers against a genuine, sustained Postgres
 * outage: an uncaught {@link org.springframework.transaction.CannotCreateTransactionException}
 * (HikariCP unable to open a connection) reached Spring MVC's {@code DispatcherServlet} with no
 * matching resolver, fell through to {@code org.springframework.web.util.DisconnectedClientHelper},
 * and was misdiagnosed as "the HTTP client disconnected" -- producing a fabricated
 * {@code 200 OK} with an empty body instead of a real error, even though the actual client was
 * still connected and waiting. Root cause: that helper explicitly excludes
 * {@link org.springframework.dao.DataAccessException} from its check ("ignore onward connection
 * issues to other servers"), but {@link org.springframework.transaction.TransactionException} --
 * the family {@code CannotCreateTransactionException} actually belongs to -- is a different
 * exception hierarchy and isn't excluded, a real gap in Spring Framework itself (spring-web
 * 7.0.8). Fixed in {@link GlobalExceptionHandler} by claiming both hierarchies explicitly before
 * {@code DispatcherServlet} ever reaches that ambiguous fallback path.
 *
 * <p><b>Honestly noted, not glossed over</b>: {@code DisconnectedClientHelper}'s misdiagnosis
 * further depends on the underlying JDBC driver's exact low-level failure message containing
 * "broken pipe" or "connection reset by peer" -- which happened live against a real, sustained
 * 3-node Patroni outage (an already-open pooled connection getting its remote peer abruptly
 * killed mid-session), but a single stopped Testcontainers Postgres container more often produces
 * a plain "connection refused" for a genuinely new connection attempt, which doesn't match either
 * phrase and so falls through to Spring Boot's own default error handling (a real 500) rather
 * than the worse fabricated-200 case. Red/green-verified directly (temporarily disabling the fix
 * and re-running): without it, {@code CannotCreateTransactionException} specifically -- reproduced
 * below via a small, fixed-size connection pool -- still resolves to the wrong status (500, not
 * 503), a real and provable regression on its own even in the environment where this test happens
 * not to reproduce the exact worst-case symptom. The fix is exception-type-based, not
 * message-text-based, so it closes both variants regardless of which one a given environment
 * happens to produce.
 *
 * <p>Not circuit-breaker-specific -- confirmed live against a plain, unmodified
 * {@code GET /api/v1/meters} with no breaker or {@code @Retryable} involved, so this test does
 * the same. A dedicated per-class Testcontainers Postgres (not {@link
 * com.gridmeter.api.support.ComponentTestSupport}'s shared singleton) is required here
 * specifically because this test needs to actually stop Postgres mid-test without breaking every
 * other component test class sharing that singleton container for the rest of the JVM run.
 */
@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class PostgresUnavailableComponentTest {

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
        // A small, fixed-size pool, deliberately -- with the real, larger pool
        // (application.yml's maximum-pool-size: 10, and HikariCP's default minimum-idle equal to
        // that), several already-open idle connections can each individually fail with
        // JpaSystemException before the pool is ever forced to open a genuinely new one, making
        // the CannotCreateTransactionException path (the actual exception behind the real bug)
        // unpredictably slow to reach. Pinning both to 2 (not 1 -- Flyway's own migration
        // connection and Hibernate's EntityManagerFactory bootstrap contended for a single slot
        // at context-startup time, unrelated to this test's actual scenario) still guarantees the
        // second post-outage call below has no surviving connection to reuse.
        registry.add("spring.datasource.hikari.maximum-pool-size", () -> "2");
        registry.add("spring.datasource.hikari.minimum-idle", () -> "2");
    }

    @LocalServerPort
    private int port;

    private String token;

    @BeforeEach
    void authenticate() {
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
    }

    @Test
    void getMeters_postgresGenuinelyUnavailable_returns503NotFabricated200() {
        // Sanity check first: Postgres is genuinely up and this call genuinely works, so the
        // 503s asserted below are a real behavior change caused by stopping Postgres, not an
        // unrelated setup problem making every call fail the same way regardless.
        given().header("Authorization", "Bearer " + token)
                .when().get("/meters")
                .then().statusCode(200);

        postgres.stop();
        try {
            // No circuit breaker or @Retryable on this read path -- this is the exact
            // unmodified-endpoint reproduction from the live incident, not a circuit-breaker
            // behavior test (ReadingServiceTest already covers the breaker's own open-state
            // behavior in isolation).
            //
            // Several calls deliberately, not one: HikariCP's already-pooled connections from
            // the sanity check (and its own minimum-idle warm-up) above are still technically
            // checked out/valid at the JDBC level when Postgres dies, so the first call(s) reuse
            // one and fail mid-use with JpaSystemException -- which is already an ordinary
            // DataAccessException, a case Spring's own DisconnectedClientHelper already excludes
            // from its "client disconnected" heuristic even without this fix (confirmed directly:
            // reverting GlobalExceptionHandler's fix and re-running showed exactly this -- a real
            // 500, not the fabricated 200 -- so asserting only one call would be a false-negative
            // regression test, passing whether or not the real fix is present). Once every pooled
            // connection (minimum-idle=2, set above) has been individually evicted this way, a
            // later call must open a genuinely NEW connection to a Postgres that no longer exists
            // -- this is what actually throws CannotCreateTransactionException, the exact
            // exception type (org.springframework.transaction.TransactionException, not
            // org.springframework.dao.DataAccessException) at the center of the real bug (see this
            // class's own Javadoc for why this environment reliably reproduces this exception type
            // but not always its worst-case fabricated-200 symptom specifically). Looping and
            // asserting every call rather than hardcoding which iteration hits which exception --
            // the exact count is an internal HikariCP timing detail, not worth pinning precisely.
            // Collected first, asserted after the loop -- not asserted inline per call -- so a
            // single early failure doesn't abort the loop before later iterations (the ones more
            // likely to have actually exhausted the pool and hit CannotCreateTransactionException)
            // ever run, which would hide exactly the evidence this test exists to capture.
            List<Response> responses = new ArrayList<>();
            for (int i = 0; i < 4; i++) {
                responses.add(given().header("Authorization", "Bearer " + token).when().get("/meters"));
            }

            // The regression this test exists to catch: without GlobalExceptionHandler's fix, at
            // least one of these responses is statusCode=200 with an empty body -- a fabricated
            // success, not a slow failure, so a naive "did it error eventually" check wouldn't
            // have caught it. Asserting every response is a real 503 with a real error body,
            // not just "not 200", so a regression to some OTHER wrong status (e.g. a bare 500)
            // still fails this test too.
            for (Response response : responses) {
                assertThat(response.statusCode()).isEqualTo(503);
                assertThat(response.jsonPath().getInt("status")).isEqualTo(503);
                assertThat(response.jsonPath().getString("error")).isEqualTo("Service Unavailable");
            }
        } finally {
            postgres.start();
        }
    }
}
