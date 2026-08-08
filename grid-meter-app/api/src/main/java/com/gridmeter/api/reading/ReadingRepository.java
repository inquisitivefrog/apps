package com.gridmeter.api.reading;

import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface ReadingRepository extends JpaRepository<Reading, UUID>, JpaSpecificationExecutor<Reading> {
}
