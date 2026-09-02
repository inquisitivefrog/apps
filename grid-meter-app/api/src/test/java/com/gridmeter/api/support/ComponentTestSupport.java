package com.gridmeter.api.support;

import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Shared base for component tests (see docs/testing-strategy.md): boots the full Spring context
 * against real Postgres/Kafka/Redis via Testcontainers, versions pinned to tech-stack-versions.md.
 * Containers are started once in a static initializer (not via {@code @Testcontainers}/{@code
 * @Container}) and shared across every subclass in this JVM run — the standard "singleton
 * container" pattern, since the per-class start/stop lifecycle those annotations impose would tear
 * a container down after the first test class and break the next one. Ryuk reaps them at JVM exit.
 *
 * <p>{@code @ActiveProfiles("test")} excludes application.yml's "!test"-gated Sentinel block, so
 * RedisAutoConfiguration falls through to plain standalone mode using the host/port registered
 * below against this class's single Redis container -- Sentinel mode isn't satisfiable here (no
 * Sentinel container is started), and would otherwise win unconditionally the moment ANY
 * spring.data.redis.sentinel.* key is present anywhere in the merged environment, regardless of
 * this class's own host/port override. See that block's own comment for the full incident.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@ActiveProfiles("test")
public abstract class ComponentTestSupport {

    protected static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse("postgres:18.4"))
                    .withDatabaseName("gridmeter")
                    .withUsername("gridmeter")
                    .withPassword("gridmeter");

    protected static final KafkaContainer KAFKA =
            new KafkaContainer(DockerImageName.parse("apache/kafka:4.3.1"));

    protected static final GenericContainer<?> REDIS =
            new GenericContainer<>(DockerImageName.parse("redis:8.10"))
                    .withExposedPorts(6379);

    static {
        POSTGRES.start();
        KAFKA.start();
        REDIS.start();
    }

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
        registry.add("spring.datasource.username", POSTGRES::getUsername);
        registry.add("spring.datasource.password", POSTGRES::getPassword);
        registry.add("spring.kafka.bootstrap-servers", KAFKA::getBootstrapServers);
        // The real values (3 replicas, min.insync.replicas=2 -- see application.yml/
        // KafkaTopicConfig) aren't satisfiable against this single-broker Testcontainers Kafka:
        // replicas=3 throws InvalidReplicationFactorException at topic creation (validated
        // against actual broker count), and min.insync.replicas=2 with only 1 broker would make
        // every produce permanently unsatisfiable even if topic creation itself didn't fail first.
        registry.add("grid-meter.kafka.readings-topic-replicas", () -> "1");
        registry.add("grid-meter.kafka.readings-topic-min-insync-replicas", () -> "1");
        registry.add("spring.data.redis.host", REDIS::getHost);
        registry.add("spring.data.redis.port", () -> REDIS.getMappedPort(6379));
    }
}
