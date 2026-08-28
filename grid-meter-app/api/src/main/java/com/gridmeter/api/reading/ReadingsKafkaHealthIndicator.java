package com.gridmeter.api.reading;

import java.util.Collection;
import java.util.concurrent.TimeUnit;
import org.apache.kafka.clients.admin.Admin;
import org.apache.kafka.common.Node;
import org.springframework.boot.health.contributor.AbstractHealthIndicator;
import org.springframework.boot.health.contributor.Health;
import org.springframework.kafka.core.KafkaAdmin;
import org.springframework.stereotype.Component;

/**
 * Spring Boot Actuator has no built-in Kafka health indicator -- an earlier one existed inside the
 * Spring Boot project itself and was removed upstream, with nothing replacing it (see
 * docs/resilience-scope.md). Registers automatically as the "readingsKafka" entry under
 * /actuator/health's "components" (only visible when management.endpoint.health.show-details
 * permits it -- see application.yml).
 *
 * <p>Deliberately does NOT use {@link KafkaAdmin#clusterId()} as the underlying check, even though
 * that looked like the obvious building block -- confirmed via its real source
 * (spring-kafka-4.1.0-sources.jar) that it caches the cluster id after the first successful call
 * and swallows any exception internally rather than propagating it. Calling it repeatedly from a
 * polled health indicator would silently stop reflecting Kafka's actual live reachability after the
 * very first success -- exactly the "looks healthy, isn't" gap this indicator exists to close, so
 * building it on {@code clusterId()} would have defeated its own purpose. Builds a short-lived
 * {@link Admin} client per check instead, from {@link KafkaAdmin}'s own configuration properties,
 * so every poll is a real, uncached {@code describeCluster()} call.
 */
@Component
public class ReadingsKafkaHealthIndicator extends AbstractHealthIndicator {

    private static final long TIMEOUT_SECONDS = 5;

    private final KafkaAdmin kafkaAdmin;

    public ReadingsKafkaHealthIndicator(KafkaAdmin kafkaAdmin) {
        this.kafkaAdmin = kafkaAdmin;
    }

    @Override
    protected void doHealthCheck(Health.Builder builder) throws Exception {
        try (Admin admin = Admin.create(kafkaAdmin.getConfigurationProperties())) {
            Collection<Node> nodes = admin.describeCluster().nodes().get(TIMEOUT_SECONDS, TimeUnit.SECONDS);
            if (nodes.isEmpty()) {
                builder.down().withDetail("reason", "describeCluster() returned zero nodes");
                return;
            }
            builder.up().withDetail("nodes", nodes.size());
        }
        // Any exception (timeout, no brokers reachable) propagates up to AbstractHealthIndicator's
        // own health(), which converts it to a DOWN status with the exception attached -- no need
        // to catch it here ourselves.
    }
}
