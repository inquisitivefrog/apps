package com.gridmeter.api.auth;

import com.gridmeter.api.auth.dto.LoginRequest;
import com.gridmeter.api.auth.dto.LoginResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.client.RestTestClient;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * The one HTTP-level test in this suite — follows GridMeterApiApplicationTests's existing
 * precedent (per-class @Testcontainers, RANDOM_PORT) since no REST Assured/MockMvc convention
 * exists yet in this project. Uses RestTestClient (Spring Framework 7 / Boot 4's replacement for
 * the now-deprecated TestRestTemplate), bound to the live server via @LocalServerPort — already on
 * the classpath via spring-test, no new dependency needed. Redis IS containerized here (unlike the
 * plain smoke test) because /actuator/health's real status depends on it — the health check would
 * otherwise report DOWN/503 with no Redis reachable, which isn't what this test is verifying.
 *
 * <p>{@code @ActiveProfiles("test")}: see {@link com.gridmeter.api.support.ComponentTestSupport}'s
 * identical annotation for why -- this class predates that fix and has its own separate
 * Testcontainers setup rather than extending ComponentTestSupport, so it needed the same
 * annotation applied directly. Without it, application.yml's "!test"-gated Sentinel block would be
 * active, and the health check below would report DOWN/503 trying to reach a nonexistent Sentinel
 * instead of this class's own plain Redis container.
 */
@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class ApiSecurityComponentTest {

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
        // See ComponentTestSupport's identical override -- this class has its own separate
        // single-broker Testcontainers Kafka, so the real replicas=3/min.insync.replicas=2
        // aren't satisfiable here either.
        registry.add("grid-meter.kafka.readings-topic-replicas", () -> "1");
        registry.add("grid-meter.kafka.readings-topic-min-insync-replicas", () -> "1");
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", () -> redis.getMappedPort(6379));
    }

    @LocalServerPort
    private int port;

    private RestTestClient client;

    @BeforeEach
    void setUp() {
        client = RestTestClient.bindToServer().baseUrl("http://localhost:" + port).build();
    }

    @Test
    void unauthenticatedRequest_toProtectedEndpoint_returns401() {
        client.get().uri("/api/v1/meters")
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void actuatorHealth_noAuthRequired_returns200() {
        client.get().uri("/actuator/health")
                .exchange()
                .expectStatus().isOk();
    }

    @Test
    void login_thenAuthenticatedRequest_succeeds() {
        LoginResponse loginResponse = client.post().uri("/api/v1/auth/login")
                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                .body(new LoginRequest("demo", "GridMeter!Demo2026"))
                .exchange()
                .expectStatus().isOk()
                .expectBody(LoginResponse.class)
                .returnResult()
                .getResponseBody();

        client.get().uri("/api/v1/meters")
                .header("Authorization", "Bearer " + loginResponse.accessToken())
                .exchange()
                .expectStatus().isOk();
    }

    @Test
    void invalidToken_toProtectedEndpoint_returns401() {
        client.get().uri("/api/v1/meters")
                .header("Authorization", "Bearer this-is-not-a-real-jwt")
                .exchange()
                .expectStatus().isEqualTo(HttpStatus.UNAUTHORIZED);
    }
}
