package com.gridmeter.api.reading;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

/** Immutable event record — no setters used post-insert, no PUT endpoint exists for this resource. */
@Entity
@Table(name = "readings")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Reading {

    @Id
    private UUID id;

    @Column(name = "meter_id", nullable = false)
    private UUID meterId;

    @Column(name = "reading_timestamp", nullable = false)
    private Instant readingTimestamp;

    @Column(name = "received_at", nullable = false)
    private Instant receivedAt;

    @Column(nullable = false, precision = 12, scale = 3)
    private BigDecimal value;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    // Enforces docs/idempotency-scope.md's actual guarantee (a unique DB constraint, not the
    // Redis fast-path) -- see V7__add_idempotency_key_to_readings.sql.
    @Column(name = "idempotency_key", nullable = false)
    private String idempotencyKey;
}
