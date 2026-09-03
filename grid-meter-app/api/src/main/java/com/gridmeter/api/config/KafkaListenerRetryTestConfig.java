package com.gridmeter.api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.listener.CommonErrorHandler;
import org.springframework.kafka.listener.DefaultErrorHandler;
import org.springframework.util.backoff.FixedBackOff;

/**
 * TEMPORARY test-only override, added to isolate docs/redis-ha-scope.md's Lettuce/Kafka-retry
 * hypothesis (see that doc's "Isolating the Lettuce/Kafka retry hypothesis" section). Only takes
 * effect when GRID_METER_KAFKA_LISTENER_MAX_ATTEMPTS is explicitly set in the environment; unset
 * (the case in every environment except this isolation test) means this bean is never registered
 * and Spring Kafka's own autoconfigured default error handler (FixedBackOff(0, 9), i.e. up to 10
 * total delivery attempts with no backoff) is left completely untouched.
 */
@Configuration
@ConditionalOnProperty("grid-meter.kafka.listener.max-attempts")
public class KafkaListenerRetryTestConfig {

    @Bean
    public CommonErrorHandler kafkaErrorHandler(
            @Value("${grid-meter.kafka.listener.max-attempts}") int maxAttempts) {
        return new DefaultErrorHandler(new FixedBackOff(0L, Math.max(0, maxAttempts - 1)));
    }
}
