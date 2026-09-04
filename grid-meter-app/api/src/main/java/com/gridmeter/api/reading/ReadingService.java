package com.gridmeter.api.reading;

import com.gridmeter.api.common.ResourceNotFoundException;
import com.gridmeter.api.meter.MeterRepository;
import com.gridmeter.api.reading.dto.ReadingRequest;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.TransientDataAccessException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.redis.core.RedisTemplate;
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

    private static final Logger log = LoggerFactory.getLogger(ReadingService.class);

    // docs/idempotency-scope.md: 24h TTL, matching typical Stripe-style windows -- no
    // session-length justification needed, just "long enough that a client's own retry logic has
    // certainly given up by then".
    private static final Duration IDEMPOTENCY_KEY_TTL = Duration.ofHours(24);

    private final ReadingRepository readingRepository;
    private final MeterRepository meterRepository;
    private final KafkaTemplate<Object, Object> kafkaTemplate;
    private final RedisTemplate<String, Object> redisTemplate;
    private final String readingsTopic;
    private final Counter deliveryFailureCounter;
    // docs/resilience-scope.md's "Where the circuit breaker applies": two independent instances,
    // not one shared breaker for the whole method -- Postgres and Kafka fail independently, and a
    // Kafka outage tripping the SAME breaker used for the Postgres check would incorrectly start
    // rejecting requests that never touched Kafka at all.
    private final CircuitBreaker postgresExistenceCheckBreaker;
    private final CircuitBreaker kafkaPublishBreaker;

    public ReadingService(
            ReadingRepository readingRepository,
            MeterRepository meterRepository,
            KafkaTemplate<Object, Object> kafkaTemplate,
            RedisTemplate<String, Object> redisTemplate,
            @Value("${grid-meter.kafka.readings-topic}") String readingsTopic,
            MeterRegistry meterRegistry,
            CircuitBreakerRegistry circuitBreakerRegistry) {
        this.readingRepository = readingRepository;
        this.meterRepository = meterRepository;
        this.kafkaTemplate = kafkaTemplate;
        this.redisTemplate = redisTemplate;
        this.readingsTopic = readingsTopic;
        // Names must match application.yml's resilience4j.circuitbreaker.instances keys exactly --
        // an unmatched name here silently falls back to Resilience4j's own undeclared defaults
        // instead of this project's explicitly-declared config, with no error at startup.
        this.postgresExistenceCheckBreaker = circuitBreakerRegistry.circuitBreaker("postgres-existence-check");
        this.kafkaPublishBreaker = circuitBreakerRegistry.circuitBreaker("kafka-publish");
        // Exported as reading_delivery_failures_total on /actuator/prometheus (Micrometer's
        // Prometheus naming convention: dots -> underscores, "_total" appended for counters).
        // Backs the "reading delivery failures" rule in observability/alerting/rules.yml, which
        // fires on ANY increase since even one occurrence is a real reading permanently lost
        // (confirmed via the 150s quorum-loss test, load-tests/kafka-ha-demo.sh). Classified as a
        // notice, not an incident (docs/observability-taxonomy.md) -- a durable, queryable record
        // rather than a page, per the same redo-path reasoning that retired the outbox pattern
        // (docs/resilience-scope.md): the data has no real downstream consequence, so losing it
        // doesn't warrant interrupting anyone in real time.
        this.deliveryFailureCounter = Counter.builder("reading.delivery.failures")
                .description("Readings whose Kafka publish failed after client-side retries were "
                        + "exhausted -- these never reach Postgres")
                .register(meterRegistry);
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
    public ReadingEvent ingest(ReadingRequest request, String idempotencyKey) {
        // Fails fast with CallNotPermittedException (mapped to 503 by GlobalExceptionHandler) if
        // the Postgres breaker is open, rather than attempting a call already known likely to
        // fail or hang -- propagates straight through @Retryable above it, since
        // CallNotPermittedException isn't in that annotation's includes list; retrying a
        // known-open breaker would defeat the point of having one. See docs/resilience-scope.md's
        // "Behavior when open" section for why this doesn't conflict with
        // PrimaryFailoverSQLExceptionOverride (HikariCP's own, narrower, connection-level fix).
        boolean meterExists = postgresExistenceCheckBreaker.executeSupplier(
                () -> meterRepository.existsById(request.meterId()));
        if (!meterExists) {
            throw new ResourceNotFoundException("Meter not found: " + request.meterId());
        }
        ReadingEvent event = new ReadingEvent(
                UUID.randomUUID(),
                request.meterId(),
                request.readingTimestamp(),
                Instant.now(),
                request.value(),
                idempotencyKey);

        // docs/idempotency-scope.md's fast path (a): a cheap Redis check that avoids republishing
        // an already-seen event to Kafka at all. This is a latency/Kafka-noise optimization on top
        // of the real guarantee, not a second attempt at it -- (b), the unique constraint the async
        // consumer enforces on insert (see ReadingEventConsumer), is what actually guarantees "no
        // second row" independent of timing, Redis availability, or how close together two retries
        // land. If this check disagrees with (b) (a narrow race slips a duplicate past this SETNX),
        // (b) wins; this path never overrides it.
        if (!shouldPublish(idempotencyKey)) {
            log.info("Idempotency key {} already seen -- not republishing to Kafka, returning the "
                    + "original result", idempotencyKey);
            return event;
        }

        // send() is fire-and-forget from the caller's perspective (ingest() returns before this
        // resolves), but the returned Future's outcome was previously discarded entirely -- a real
        // Kafka quorum-loss test (150s outage, exceeding the delivery.timeout.ms client default of
        // 120000ms, now declared explicitly below) confirmed this let 10 readings silently vanish:
        // POST /readings returned 201 for all 10, and none of them ever reached Postgres, with
        // nothing logged anywhere pointing at why.
        //
        // A transactional-outbox pattern (write the failed delivery to a durable side table
        // instead of just logging it) was built and load-tested here, then deliberately retired
        // (docs/resilience-scope.md): a real load test found the outbox only ever captured the
        // narrow window before Traefik's own health check took the API out of rotation during a
        // Kafka outage, and -- separately -- an outbox with no reconciler to drain it back to
        // Kafka/Postgres isn't durability, just an ever-growing, never-queried table. This
        // project's redo-path analysis (a simulated meter reading has no real downstream
        // consequence if lost -- no billing, no regulatory record, nothing to redo) concluded
        // that gap isn't worth the reconciler it would take to close properly. The counter+log
        // below, plus the "reading delivery failures" alert (observability/alerting/rules.yml),
        // is the accepted, sufficient signal: an operator learns a reading was lost and roughly
        // when, which is all anyone would act on for data with no real consequence.
        //
        // Circuit-breaker-gated, independently of the Postgres breaker above (see class-level
        // comment). Checked via tryAcquirePermission() + manual onSuccess/onError, not
        // executeSupplier(), because send() is asynchronous -- its real success/failure outcome
        // isn't known until the returned future completes, arbitrarily later than this call
        // returns, so the breaker's sliding window has to be updated from inside whenComplete(),
        // not from whether send() itself returned without throwing. Still wrapped in a try/catch
        // around the initiating call too: Spring Kafka's KafkaTemplate.send() is documented to
        // complete its returned future exceptionally rather than throw synchronously, but nothing
        // guarantees every possible failure path honors that, and a breaker that only ever sees
        // the async path would silently under-count failures if it doesn't.
        //
        // A real, worth-stating-honestly limitation: this breaker does NOT make the first several
        // failing calls fast. max.block.ms (60s, declared above) still bounds how long send()
        // itself can block before this code even reaches tryAcquirePermission() on a SUBSEQUENT
        // call, and delivery.timeout.ms (120s) still bounds how long a single call's outcome takes
        // to resolve once sent -- both unchanged by this work. The breaker's benefit is specific to
        // the OPEN state: once enough recent calls have failed, later requests stop paying that
        // same cost at all, rather than every request during a long outage independently blocking
        // for up to a minute before failing.
        if (!kafkaPublishBreaker.tryAcquirePermission()) {
            throw CallNotPermittedException.createCallNotPermittedException(kafkaPublishBreaker);
        }
        long kafkaCallStartNanos = System.nanoTime();
        try {
            kafkaTemplate.send(readingsTopic, event.meterId().toString(), event)
                    .whenComplete((result, ex) -> {
                        long elapsedNanos = System.nanoTime() - kafkaCallStartNanos;
                        if (ex != null) {
                            kafkaPublishBreaker.onError(elapsedNanos, TimeUnit.NANOSECONDS, ex);
                            deliveryFailureCounter.increment();
                            log.error(
                                    "Reading for meter {} (readingTimestamp={}, value={}) failed to publish to "
                                            + "Kafka after client-side retries were exhausted -- this reading is "
                                            + "lost, not just delayed (see docs/resilience-scope.md)",
                                    event.meterId(), event.readingTimestamp(), event.value(), ex);
                        } else {
                            kafkaPublishBreaker.onSuccess(elapsedNanos, TimeUnit.NANOSECONDS);
                        }
                    });
        } catch (RuntimeException ex) {
            kafkaPublishBreaker.onError(System.nanoTime() - kafkaCallStartNanos, TimeUnit.NANOSECONDS, ex);
            throw ex;
        }
        return event;
    }

    // docs/idempotency-scope.md's SETNX fast path: true means "not seen before, go ahead and
    // publish"; false means "already seen, skip republishing to Kafka". Redis unavailable ->
    // fail open (returns true) rather than blocking ingest on a cache being down -- the real
    // guarantee is the unique DB constraint in ReadingEventConsumer, not this check.
    private boolean shouldPublish(String idempotencyKey) {
        String key = "idempotency:" + idempotencyKey;
        try {
            Boolean isNew = redisTemplate.opsForValue().setIfAbsent(key, "1", IDEMPOTENCY_KEY_TTL);
            return Boolean.TRUE.equals(isNew);
        } catch (DataAccessException ex) {
            log.warn("Redis unavailable while checking idempotency key {} -- failing open and "
                    + "publishing anyway (see docs/idempotency-scope.md)", idempotencyKey, ex);
            return true;
        }
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
