package com.gridmeter.api.reading.dto;

import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

public record ReadingRequest(
        @NotNull UUID meterId,
        @NotNull Instant readingTimestamp,
        @NotNull BigDecimal value) {
}
