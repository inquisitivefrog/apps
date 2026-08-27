package com.gridmeter.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.ApplicationContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Boots the full context against real Postgres/Kafka via Testcontainers to catch wiring mistakes
 * (bean generics, migration syntax, property keys) that a mocked slice test would miss. Redis is
 * assumed reachable at its default localhost port for this smoke test; component tests per
 * testing-strategy.md will cover real behavior against all three backing services.
 */
@Testcontainers
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class GridMeterApiApplicationTests {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>(DockerImageName.parse("postgres:18.4"))
            .withDatabaseName("gridmeter")
            .withUsername("gridmeter")
            .withPassword("gridmeter");

    @Container
    static KafkaContainer kafka = new KafkaContainer(DockerImageName.parse("apache/kafka:4.3.1"));

    @DynamicPropertySource
    static void registerProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
        // See ComponentTestSupport's identical override for why -- this class has its own separate
        // single-broker Testcontainers Kafka, so it needs the same real-values-aren't-satisfiable
        // override independently.
        registry.add("grid-meter.kafka.readings-topic-replicas", () -> "1");
        registry.add("grid-meter.kafka.readings-topic-min-insync-replicas", () -> "1");
    }

    @Test
    void contextLoads(ApplicationContext context) {
        assertThat(context).isNotNull();
    }
}
