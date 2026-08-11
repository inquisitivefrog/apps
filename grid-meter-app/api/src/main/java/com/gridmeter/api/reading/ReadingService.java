package com.gridmeter.api.reading;

import com.gridmeter.api.common.ResourceNotFoundException;
import com.gridmeter.api.meter.MeterRepository;
import com.gridmeter.api.reading.dto.ReadingRequest;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;

/**
 * Ingest is async: the service publishes a {@link ReadingEvent} to Kafka and returns immediately;
 * {@link ReadingEventConsumer} performs the durable Postgres write and Redis cache update. See
 * architecture.md's Controller -> Service -> Kafka -> consumer flow.
 */
@Service
public class ReadingService {

    private final ReadingRepository readingRepository;
    private final MeterRepository meterRepository;
    private final KafkaTemplate<Object, Object> kafkaTemplate;
    private final String readingsTopic;

    public ReadingService(
            ReadingRepository readingRepository,
            MeterRepository meterRepository,
            KafkaTemplate<Object, Object> kafkaTemplate,
            @Value("${grid-meter.kafka.readings-topic}") String readingsTopic) {
        this.readingRepository = readingRepository;
        this.meterRepository = meterRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.readingsTopic = readingsTopic;
    }

    public ReadingEvent ingest(ReadingRequest request) {
        if (!meterRepository.existsById(request.meterId())) {
            throw new ResourceNotFoundException("Meter not found: " + request.meterId());
        }
        ReadingEvent event = new ReadingEvent(
                UUID.randomUUID(),
                request.meterId(),
                request.readingTimestamp(),
                Instant.now(),
                request.value());
        kafkaTemplate.send(readingsTopic, event.meterId().toString(), event);
        return event;
    }

    public Reading findById(UUID id) {
        return readingRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Reading not found: " + id));
    }

    public Page<Reading> search(
            UUID meterId, Instant from, Instant to, BigDecimal minValue, BigDecimal maxValue, Pageable pageable) {
        Specification<Reading> spec = Specification.allOf();
        if (meterId != null) {
            spec = spec.and((root, query, cb) -> cb.equal(root.get("meterId"), meterId));
        }
        if (from != null) {
            spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("readingTimestamp"), from));
        }
        if (to != null) {
            spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("readingTimestamp"), to));
        }
        if (minValue != null) {
            spec = spec.and((root, query, cb) -> cb.greaterThanOrEqualTo(root.get("value"), minValue));
        }
        if (maxValue != null) {
            spec = spec.and((root, query, cb) -> cb.lessThanOrEqualTo(root.get("value"), maxValue));
        }
        return readingRepository.findAll(spec, pageable);
    }

    public void delete(UUID id) {
        if (!readingRepository.existsById(id)) {
            throw new ResourceNotFoundException("Reading not found: " + id);
        }
        readingRepository.deleteById(id);
    }
}
