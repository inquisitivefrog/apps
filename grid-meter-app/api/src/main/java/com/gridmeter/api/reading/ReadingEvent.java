package com.gridmeter.api.reading;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/**
 * Kafka payload published by the API on ingest and consumed by {@link ReadingEventConsumer}.
 * {@code idempotencyKey} travels with the event itself (not looked up separately by the consumer)
 * so the async insert can enforce docs/idempotency-scope.md's uniqueness guarantee without a
 * second round-trip back to the producer's own request context.
 */
public record ReadingEvent(
        UUID id,
        UUID meterId,
        Instant readingTimestamp,
        Instant receivedAt,
        BigDecimal value,
        String idempotencyKey) {
}
