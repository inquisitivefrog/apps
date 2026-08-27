package com.gridmeter.api.meter;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "meters")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Meter {

    @Id
    private UUID id;

    @Column(name = "serial_number", nullable = false, unique = true)
    private String serialNumber;

    @Column(nullable = false)
    private String location;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MeterStatus status;

    @Column(name = "installed_at", nullable = false)
    private Instant installedAt;

    // Flat FK field, not a JPA relation -- same convention as Reading.meterId. Every meter belongs
    // to exactly one customer (docs/multi-tenancy-scope.md); observability-only tenancy for this
    // pass, so this doesn't gate API access, only reporting.
    @Column(name = "customer_id", nullable = false)
    private UUID customerId;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
