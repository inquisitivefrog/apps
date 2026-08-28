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

/**
 * Stage A of docs/resilience-scope.md's outbox pattern (write path only, no reconciler yet) --
 * holds a reading whose Kafka publish failed after client-side retries were exhausted, so it isn't
 * lost outright the way it was before this existed. See ReadingService.ingest()'s whenComplete
 * callback.
 */
@Entity
@Table(name = "reading_outbox")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ReadingOutbox {

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
}
