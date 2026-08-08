package com.gridmeter.api.meter;

import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface MeterRepository extends JpaRepository<Meter, UUID>, JpaSpecificationExecutor<Meter> {

    Optional<Meter> findBySerialNumber(String serialNumber);
}
