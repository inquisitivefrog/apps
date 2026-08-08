package com.gridmeter.api.meter.dto;

import com.gridmeter.api.meter.Meter;
import com.gridmeter.api.meter.MeterStatus;
import java.time.Instant;
import java.util.UUID;

public record MeterResponse(
        UUID id,
        String serialNumber,
        String location,
        MeterStatus status,
        Instant installedAt,
        Instant createdAt,
        Instant updatedAt) {

    public static MeterResponse from(Meter meter) {
        return new MeterResponse(
                meter.getId(),
                meter.getSerialNumber(),
                meter.getLocation(),
                meter.getStatus(),
                meter.getInstalledAt(),
                meter.getCreatedAt(),
                meter.getUpdatedAt());
    }
}
