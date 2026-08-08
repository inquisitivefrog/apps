package com.gridmeter.api.reading;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Cache-aside payload stored in Redis under {@code reading:latest:<meterId>}. */
public record LatestReading(UUID meterId, Instant readingTimestamp, BigDecimal value) {

    public static LatestReading from(ReadingEvent event) {
        return new LatestReading(event.meterId(), event.readingTimestamp(), event.value());
    }
}
