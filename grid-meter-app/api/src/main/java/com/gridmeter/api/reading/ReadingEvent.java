package com.gridmeter.api.reading;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Kafka payload published by the API on ingest and consumed by {@link ReadingEventConsumer}. */
public record ReadingEvent(
        UUID id,
        UUID meterId,
        Instant readingTimestamp,
        Instant receivedAt,
        BigDecimal value) {
}
