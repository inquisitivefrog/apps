package com.gridmeter.api.meter;

import com.gridmeter.api.common.ResourceNotFoundException;
import com.gridmeter.api.meter.dto.MeterRequest;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MeterService {

    private final MeterRepository meterRepository;

    public MeterService(MeterRepository meterRepository) {
        this.meterRepository = meterRepository;
    }

    @Transactional
    public Meter create(MeterRequest request) {
        Instant now = Instant.now();
        Meter meter = Meter.builder()
                .id(UUID.randomUUID())
                .serialNumber(request.serialNumber())
                .location(request.location())
                .status(request.status())
                .installedAt(request.installedAt())
                .createdAt(now)
                .updatedAt(now)
                .build();
        return meterRepository.save(meter);
    }

    public Meter findById(UUID id) {
        return meterRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Meter not found: " + id));
    }

    public Page<Meter> search(String location, MeterStatus status, Pageable pageable) {
        Specification<Meter> spec = Specification.allOf();
        if (location != null && !location.isBlank()) {
            spec = spec.and((root, query, cb) ->
                    cb.like(cb.lower(root.get("location")), "%" + location.toLowerCase() + "%"));
        }
        if (status != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("status"), status));
        }
        return meterRepository.findAll(spec, pageable);
    }

    @Transactional
    public Meter update(UUID id, MeterRequest request) {
        Meter meter = findById(id);
        meter.setSerialNumber(request.serialNumber());
        meter.setLocation(request.location());
        meter.setStatus(request.status());
        meter.setInstalledAt(request.installedAt());
        meter.setUpdatedAt(Instant.now());
        return meterRepository.save(meter);
    }

    @Transactional
    public void delete(UUID id) {
        if (!meterRepository.existsById(id)) {
            throw new ResourceNotFoundException("Meter not found: " + id);
        }
        meterRepository.deleteById(id);
    }
}
