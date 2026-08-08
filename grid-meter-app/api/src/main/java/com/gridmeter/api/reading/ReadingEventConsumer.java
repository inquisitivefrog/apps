package com.gridmeter.api.reading;

import java.time.Duration;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * Durable write path: consumes {@link ReadingEvent} off Kafka, persists it to Postgres (system of
 * record) and refreshes the per-meter latest-reading entry in Redis, per architecture.md's data flow.
 */
@Component
public class ReadingEventConsumer {

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
                .build();
        readingRepository.save(reading);

        String key = "reading:latest:" + event.meterId();
        redisTemplate.opsForValue().set(key, LatestReading.from(event), LATEST_READING_TTL);
    }
}
