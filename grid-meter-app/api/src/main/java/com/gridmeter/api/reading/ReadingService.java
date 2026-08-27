package com.gridmeter.api.reading;

import com.gridmeter.api.common.ResourceNotFoundException;
import com.gridmeter.api.meter.MeterRepository;
import com.gridmeter.api.reading.dto.ReadingRequest;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.springframework.dao.TransientDataAccessException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.orm.jpa.JpaSystemException;
import org.springframework.resilience.annotation.Retryable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.CannotCreateTransactionException;

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

    // A brief, self-resolving Postgres blip (a failover completing, a momentary connection-pool
    // squeeze, an already-open pooled connection getting killed server-side) shouldn't have to
    // surface as a hard failure just because meterRepository.existsById() below happened to hit
    // it on its first attempt -- retry 3 times total (standard practice) with a short exponential
    // backoff before giving up for real. Uses Spring Framework 7's own native @Retryable
    // (org.springframework.resilience.annotation, backed by @EnableResilientMethods on the main
    // application class) rather than the older spring-retry library -- no extra dependency
    // needed, since spring-context (already required regardless) ships this natively. Scoped to
    // specific exception types via includes(), not a blanket catch-all, so a genuinely missing
    // meter (ResourceNotFoundException, thrown below) is never retried -- that's not a transient
    // condition, retrying it would just waste attempts on a request that was always going to
    // fail. CannotCreateTransactionException covers "can't acquire a new pooled connection" (the
    // chaos-demo postgres-outage scenario this was originally built for); JpaSystemException
    // covers a different, empirically-confirmed real case: a real test killed Postgres
    // mid-request and got "JpaSystemException: Unable to rollback against JDBC Connection" (root
    // cause: "Connection is closed", from an already-open pooled connection Postgres terminated
    // server-side) -- Spring's own hierarchy classifies JpaSystemException as non-transient by
    // default, which is the wrong call for this specific case, hence listing it explicitly rather
    // than trusting TransientDataAccessException alone to cover it. maxRetries=2 here means 3
    // total attempts (1 initial + 2 retries, per this annotation's own documented semantics).
    // Each attempt still fails fast on its own (see spring.datasource.hikari.connection-timeout
    // in application.yml, 5s) -- this decouples how long one attempt waits from how long the
    // overall request tolerates a transient outage, rather than just making the single timeout
    // itself longer.
    @Retryable(
            includes = {
                TransientDataAccessException.class,
                CannotCreateTransactionException.class,
                JpaSystemException.class
            },
            maxRetries = 2,
            delay = 200,
            multiplier = 2)
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
