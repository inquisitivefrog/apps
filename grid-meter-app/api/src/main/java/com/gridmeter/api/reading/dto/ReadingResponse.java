package com.gridmeter.api.reading.dto;

import com.gridmeter.api.reading.Reading;
import com.gridmeter.api.reading.ReadingEvent;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ReadingResponse(
        UUID id,
        UUID meterId,
        Instant readingTimestamp,
        Instant receivedAt,
        BigDecimal value) {

    public static ReadingResponse from(Reading reading) {
        return new ReadingResponse(
                reading.getId(),
                reading.getMeterId(),
                reading.getReadingTimestamp(),
                reading.getReceivedAt(),
                reading.getValue());
    }

    public static ReadingResponse from(ReadingEvent event) {
        return new ReadingResponse(
                event.id(),
                event.meterId(),
                event.readingTimestamp(),
                event.receivedAt(),
                event.value());
    }
}
