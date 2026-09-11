package com.gridmeter.api.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

/**
 * Confirms the "cloud" Spring profile (docs/cloud-deployment-scope.md's gating read-through, added
 * 2026-09-11) actually wires a plain standalone Redis connection, not Sentinel -- the "confirm the
 * actual wiring, not just that it compiles" discipline this project applies to every Redis
 * config change (see application.yml's "!test & !cloud" Sentinel block and its "cloud" profile
 * counterpart for the full reasoning).
 *
 * <p>Doesn't extend {@link com.gridmeter.api.support.ComponentTestSupport} -- that class hardcodes
 * {@code @ActiveProfiles("test")}, which would activate the wrong exclusion path ("!test" is what
 * turns Sentinel off there, not "!cloud"). Runs its own dedicated Postgres/Kafka/Redis containers
 * instead, the same pattern {@code PostgresUnavailableComponentTest} already uses when a test's
 * profile/lifecycle needs genuinely diverge from the shared singleton support class.
 *
 * <p>No local cluster exists yet to validate a real managed-Redis failover against this profile --
 * that's expected at this stage (docs/cloud-deployment-scope.md), not a gap this test tries to
 * cover. What this confirms is that the app is *capable* of running against a single endpoint at
 * all: the connection factory's own mode, not a live failover.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.NONE)
@ActiveProfiles("cloud")
class RedisCloudProfileComponentTest {

    private static final PostgreSQLContainer<?> POSTGRES =
            new PostgreSQLContainer<>(DockerImageName.parse("postgres:18.4"))
                    .withDatabaseName("gridmeter")
                    .withUsername("gridmeter")
                    .withPassword("gridmeter");

    private static final KafkaContainer KAFKA =
            new KafkaContainer(DockerImageName.parse("apache/kafka:4.3.1"));

    // A plain Redis container, not Sentinel-fronted -- deliberately shaped like the managed
    // endpoint this profile targets (a single reachable host:port, no Sentinel process to
    // discover), not a re-run of the Sentinel topology docs/redis-ha-scope.md already covers.
    private static final GenericContainer<?> REDIS =
            new GenericContainer<>(DockerImageName.parse("redis:8.10")).withExposedPorts(6379);

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
        // Same single-broker accommodation as ComponentTestSupport -- the real replicas=3/
        // min-insync-replicas=2 values aren't satisfiable against this one-broker Testcontainers
        // Kafka, and this test has nothing to do with Kafka HA anyway.
        registry.add("grid-meter.kafka.readings-topic-replicas", () -> "1");
        registry.add("grid-meter.kafka.readings-topic-min-insync-replicas", () -> "1");
        // Satisfies the "cloud" profile block's own ${SPRING_DATA_REDIS_HOST}/
        // ${SPRING_DATA_REDIS_PORT} placeholders exactly the way a real deployment's env vars
        // would -- registering these two names (not spring.data.redis.host/port directly) means
        // this test genuinely exercises the placeholder-resolution path the profile actually
        // uses, not a bypass of it.
        registry.add("SPRING_DATA_REDIS_HOST", REDIS::getHost);
        registry.add("SPRING_DATA_REDIS_PORT", () -> REDIS.getMappedPort(6379));
    }

    @Autowired
    private RedisConnectionFactory redisConnectionFactory;

    @Test
    void cloudProfile_wiresStandaloneRedis_notSentinel() {
        assertThat(redisConnectionFactory).isInstanceOf(LettuceConnectionFactory.class);
        LettuceConnectionFactory lettuce = (LettuceConnectionFactory) redisConnectionFactory;

        // The direct, source-confirmed signal (DataRedisConnectionConfiguration.determineMode()):
        // Mode.STANDALONE is chosen precisely because no spring.data.redis.sentinel.* config
        // exists in this profile's merged environment -- not inferred from the absence of an
        // error, asserted against the connection factory's own reported mode.
        assertThat(lettuce.isRedisSentinelAware()).isFalse();
        assertThat(lettuce.getSentinelConfiguration()).isNull();
        assertThat(lettuce.getStandaloneConfiguration()).isNotNull();
        assertThat(lettuce.getHostName()).isEqualTo(REDIS.getHost());
        assertThat(lettuce.getPort()).isEqualTo(REDIS.getMappedPort(6379));

        // Confirms the wiring actually works end-to-end against the managed-Redis-shaped
        // endpoint, not just that the bean's own fields look right.
        assertThat(redisConnectionFactory.getConnection().ping()).isEqualTo("PONG");
    }
}
