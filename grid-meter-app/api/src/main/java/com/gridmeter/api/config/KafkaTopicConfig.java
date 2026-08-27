package com.gridmeter.api.config;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

    // replicas/minInsyncReplicas come from properties, not hardcoded, specifically so
    // ComponentTestSupport's single-broker Testcontainers Kafka can override both to 1 --
    // .replicas(3) against a 1-broker cluster throws InvalidReplicationFactorException at topic
    // creation (validated against actual broker count), and even if replicas were left at the
    // real value, min.insync.replicas=2 against a 1-broker cluster would make every produce
    // permanently unsatisfiable (never 2 in-sync replicas to acknowledge). Production value
    // (replicas=3, matching the 3-broker cluster in docker-compose.yml/docs/ha-scope.md) means
    // every partition has a copy on every broker; min.insync.replicas=2 with acks=all (the Kafka
    // client's own default since idempotence became default-on in 3.0) means a write needs 2
    // in-sync replicas to succeed -- tolerates one broker down without losing durability, but
    // correctly refuses writes if a second broker is also lost.
    @Bean
    public NewTopic readingsTopic(
            @Value("${grid-meter.kafka.readings-topic}") String topicName,
            @Value("${grid-meter.kafka.readings-topic-replicas}") short replicas,
            @Value("${grid-meter.kafka.readings-topic-min-insync-replicas}") String minInsyncReplicas) {
        return TopicBuilder.name(topicName)
                .partitions(3)
                .replicas(replicas)
                .config("min.insync.replicas", minInsyncReplicas)
                .build();
    }
}
