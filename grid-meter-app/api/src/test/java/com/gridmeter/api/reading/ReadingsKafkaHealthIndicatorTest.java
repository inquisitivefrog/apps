package com.gridmeter.api.reading;

import static org.assertj.core.api.Assertions.assertThat;

import com.gridmeter.api.support.ComponentTestSupport;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.health.contributor.Health;
import org.springframework.boot.health.contributor.Status;

/**
 * Only covers the UP case against the real (shared, singleton) Testcontainers Kafka -- deliberately
 * does NOT stop that container to exercise the DOWN case, since ComponentTestSupport's containers
 * are shared across every test class in the same JVM run (see its own Javadoc); stopping it here
 * would break Kafka connectivity for every other test class running afterward. The DOWN case (all
 * brokers unreachable) was verified live instead, against the real 3-broker docker-compose cluster:
 * stopped all three, confirmed /actuator/health's aggregate status flipped to DOWN, restarted them,
 * confirmed it recovered to UP.
 */
class ReadingsKafkaHealthIndicatorTest extends ComponentTestSupport {

    @Autowired
    private ReadingsKafkaHealthIndicator healthIndicator;

    @Test
    void health_kafkaReachable_reportsUpWithNodeCount() {
        Health health = healthIndicator.health();

        assertThat(health.getStatus()).isEqualTo(Status.UP);
        assertThat(health.getDetails()).containsKey("nodes");
    }
}
