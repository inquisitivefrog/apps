package com.gridmeter.api.reading;

import java.time.Duration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Durable write path: consumes {@link ReadingEvent} off Kafka, persists it to Postgres (system of
 * record) and refreshes the per-meter latest-reading entry in Redis, per architecture.md's data flow.
 */
@Component
public class ReadingEventConsumer {

    private static final Logger log = LoggerFactory.getLogger(ReadingEventConsumer.class);

    private static final Duration LATEST_READING_TTL = Duration.ofDays(7);

    private final ReadingRepository readingRepository;
    private final RedisTemplate<String, Object> redisTemplate;

    public ReadingEventConsumer(ReadingRepository readingRepository, RedisTemplate<String, Object> redisTemplate) {
        this.readingRepository = readingRepository;
        this.redisTemplate = redisTemplate;
    }

    @KafkaListener(topics = "${grid-meter.kafka.readings-topic}")
    public void onReadingEvent(ReadingEvent event) {
        Reading reading = Reading.builder()
                .id(event.id())
                .meterId(event.meterId())
                .readingTimestamp(event.readingTimestamp())
                .receivedAt(event.receivedAt())
                .value(event.value())
                .createdAt(event.receivedAt())
                .idempotencyKey(event.idempotencyKey())
                .build();

        // docs/idempotency-scope.md's real guarantee: the unique index on idempotency_key
        // (V7__add_idempotency_key_to_readings.sql), not the Redis fast-path in ReadingService,
        // is what actually prevents a second row -- this catch is what makes that true regardless
        // of Redis's state, timing, or how close together two retries land. A duplicate is
        // expected, normal traffic (a client retry that both the client and the Redis check missed
        // classifying), not a system failure, so it's logged and discarded rather than crashing
        // this Kafka listener or being sent to a dead-letter topic.
        try {
            readingRepository.save(reading);
        } catch (DataIntegrityViolationException ex) {
            log.info("Idempotency key {} already exists in readings -- discarding duplicate event "
                    + "for meter {} (see docs/idempotency-scope.md)", event.idempotencyKey(), event.meterId());
            return;
        }

        String key = "reading:latest:" + event.meterId();
        redisTemplate.opsForValue().set(key, LatestReading.from(event), LATEST_READING_TTL);
    }
}
