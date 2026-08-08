package com.gridmeter.api.meter.dto;

import com.gridmeter.api.meter.MeterStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

public record MeterRequest(
        @NotBlank String serialNumber,
        @NotBlank String location,
        @NotNull MeterStatus status,
        @NotNull Instant installedAt) {
}
