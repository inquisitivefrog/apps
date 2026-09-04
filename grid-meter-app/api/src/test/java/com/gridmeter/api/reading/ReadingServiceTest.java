package com.gridmeter.api.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.gridmeter.api.meter.MeterRepository;
import com.gridmeter.api.reading.dto.ReadingRequest;
import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataRetrievalFailureException;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

/**
 * Pure unit test (Mockito) for the delivery-failure visibility fix -- see ReadingService.ingest()'s
 * own comment. Deliberately not a Testcontainers-based test forcing a real 120s
 * delivery.timeout.ms wait: mocking the returned Future's outcome is faster and just as decisive
 * for verifying the counter/log side effects, which don't depend on real Kafka timing.
 */
class ReadingServiceTest {

    // Small windows relative to production's (application.yml: 10/20/50%/10s/5), not because the
    // logic under test differs, but so these tests don't need 10 real calls or a real 10s wait to
    // exercise open/half-open transitions. Same instance names as production
    // ("postgres-existence-check"/"kafka-publish") so ReadingService's own lookup-by-name wiring
    // is exercised for real, not bypassed.
    private static final int SLIDING_WINDOW_SIZE = 4;
    private static final int MINIMUM_NUMBER_OF_CALLS = 4;
    private static final Duration WAIT_DURATION_IN_OPEN_STATE = Duration.ofMillis(200);
    private static final int PERMITTED_CALLS_IN_HALF_OPEN = 2;

    private MeterRepository meterRepository;
    private KafkaTemplate<Object, Object> kafkaTemplate;
    private RedisTemplate<String, Object> redisTemplate;
    private SimpleMeterRegistry meterRegistry;
    private CircuitBreakerRegistry circuitBreakerRegistry;
    private ReadingService readingService;
    private ListAppender<ILoggingEvent> logAppender;

    @BeforeEach
    void setUp() {
        meterRepository = mock(MeterRepository.class);
        kafkaTemplate = mock(KafkaTemplate.class);
        redisTemplate = mock(RedisTemplate.class);
        ValueOperations<String, Object> valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        // Default: every idempotency key looks new, so existing tests (none of which are about
        // idempotency behavior) exercise the normal publish path unless a test overrides this.
        when(valueOperations.setIfAbsent(anyString(), any(), any(Duration.class))).thenReturn(true);
        meterRegistry = new SimpleMeterRegistry();
        CircuitBreakerConfig testConfig = CircuitBreakerConfig.custom()
                .slidingWindowType(CircuitBreakerConfig.SlidingWindowType.COUNT_BASED)
                .slidingWindowSize(SLIDING_WINDOW_SIZE)
                .minimumNumberOfCalls(MINIMUM_NUMBER_OF_CALLS)
                .failureRateThreshold(50)
                .waitDurationInOpenState(WAIT_DURATION_IN_OPEN_STATE)
                .permittedNumberOfCallsInHalfOpenState(PERMITTED_CALLS_IN_HALF_OPEN)
                .automaticTransitionFromOpenToHalfOpenEnabled(false)
                .build();
        circuitBreakerRegistry = CircuitBreakerRegistry.of(testConfig);
        readingService = new ReadingService(
                mock(ReadingRepository.class),
                meterRepository,
                kafkaTemplate,
                redisTemplate,
                "readings",
                meterRegistry,
                circuitBreakerRegistry);

        logAppender = new ListAppender<>();
        logAppender.start();
        ((Logger) LoggerFactory.getLogger(ReadingService.class)).addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        ((Logger) LoggerFactory.getLogger(ReadingService.class)).detachAppender(logAppender);
    }

    @Test
    void ingest_kafkaDeliveryFails_incrementsCounterAndLogs() {
        UUID meterId = UUID.randomUUID();
        Instant readingTimestamp = Instant.parse("2026-08-28T12:00:00Z");
        BigDecimal value = new BigDecimal("42.5");
        when(meterRepository.existsById(meterId)).thenReturn(true);
        CompletableFuture<SendResult<Object, Object>> failedFuture =
                CompletableFuture.failedFuture(new RuntimeException("Expiring record(s): delivery.timeout.ms exceeded"));
        when(kafkaTemplate.send(anyString(), any(), any())).thenReturn(failedFuture);

        ReadingEvent event =
                readingService.ingest(new ReadingRequest(meterId, readingTimestamp, value), UUID.randomUUID().toString());

        assertThat(event.meterId()).isEqualTo(meterId);
        assertThat(meterRegistry.get("reading.delivery.failures").counter().count()).isEqualTo(1.0);
        assertThat(logAppender.list).anySatisfy(logEvent -> {
            assertThat(logEvent.getLevel().toString()).isEqualTo("ERROR");
            assertThat(logEvent.getFormattedMessage())
                    .contains(meterId.toString())
                    .contains(readingTimestamp.toString())
                    .contains("42.5");
        });
    }

    @Test
    void ingest_kafkaDeliverySucceeds_doesNotIncrementCounterOrLogError() {
        UUID meterId = UUID.randomUUID();
        when(meterRepository.existsById(meterId)).thenReturn(true);
        when(kafkaTemplate.send(anyString(), any(), any()))
                .thenReturn(CompletableFuture.completedFuture(mock(SendResult.class)));

        readingService.ingest(new ReadingRequest(meterId, Instant.now(), BigDecimal.TEN), UUID.randomUUID().toString());

        // The counter is registered eagerly in the constructor (so it always appears on
        // /actuator/prometheus, even at zero, rather than only after the first-ever failure) --
        // asserting count=0 here, not that the counter is absent.
        assertThat(meterRegistry.get("reading.delivery.failures").counter().count()).isEqualTo(0.0);
        assertThat(logAppender.list).noneMatch(logEvent -> logEvent.getLevel().toString().equals("ERROR"));
    }

    private ReadingEvent ingestOnce(UUID meterId) {
        return readingService.ingest(
                new ReadingRequest(meterId, Instant.now(), BigDecimal.ONE), UUID.randomUUID().toString());
    }

    // docs/resilience-scope.md's "Where the circuit breaker applies" + "Testing implications":
    // the breaker opens only once BOTH minimum-number-of-calls and failure-rate-threshold are
    // crossed, not on the first failure -- and once open, further calls fail fast via
    // CallNotPermittedException instead of reaching meterRepository.existsById() at all.
    @Test
    void postgresBreaker_opensOnlyAfterMinimumCallsAndFailureThresholdCrossed() {
        UUID meterId = UUID.randomUUID();
        when(meterRepository.existsById(meterId))
                .thenThrow(new DataRetrievalFailureException("simulated Postgres failure"));
        CircuitBreaker breaker = circuitBreakerRegistry.circuitBreaker("postgres-existence-check");
        assertThat(breaker.getState()).isEqualTo(CircuitBreaker.State.CLOSED);

        for (int i = 0; i < MINIMUM_NUMBER_OF_CALLS - 1; i++) {
            assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(DataRetrievalFailureException.class);
        }
        // Below minimum-number-of-calls -- Resilience4j doesn't evaluate the failure rate yet,
        // regardless of how many of those calls failed.
        assertThat(breaker.getState()).isEqualTo(CircuitBreaker.State.CLOSED);

        // The MINIMUM_NUMBER_OF_CALLS-th call crosses the threshold: 100% failure rate, above the
        // configured 50%.
        assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(DataRetrievalFailureException.class);
        assertThat(breaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);

        // Open now -- fails fast without ever calling existsById() again.
        int callsBeforeOpen = MINIMUM_NUMBER_OF_CALLS;
        assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(CallNotPermittedException.class);
        verify(meterRepository, times(callsBeforeOpen)).existsById(meterId);
    }

    // Half-open: a bounded number of probe calls, closing on continued success.
    @Test
    void postgresBreaker_halfOpen_closesAfterProbeCallsSucceed() throws InterruptedException {
        UUID meterId = UUID.randomUUID();
        when(meterRepository.existsById(meterId))
                .thenThrow(new DataRetrievalFailureException("simulated Postgres failure"));
        CircuitBreaker breaker = circuitBreakerRegistry.circuitBreaker("postgres-existence-check");
        for (int i = 0; i < MINIMUM_NUMBER_OF_CALLS; i++) {
            assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(DataRetrievalFailureException.class);
        }
        assertThat(breaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);

        Thread.sleep(WAIT_DURATION_IN_OPEN_STATE.toMillis() + 100);
        // doReturn().when(), not when().thenReturn(): the mock currently has a thenThrow() stub
        // for this exact call, and when(mock.method()) works by actually invoking method() to
        // record it -- which would re-trigger the existing throw before the new stub ever gets
        // attached. doReturn() sidesteps that by never calling the real method during setup.
        doReturn(true).when(meterRepository).existsById(meterId);
        when(kafkaTemplate.send(anyString(), any(), any()))
                .thenReturn(CompletableFuture.completedFuture(mock(SendResult.class)));

        // automaticTransitionFromOpenToHalfOpenEnabled=false (matching production) -- the
        // transition only happens on the next access attempt after the wait duration, not on a
        // background thread, so the first post-wait call is itself the first half-open probe.
        for (int i = 0; i < PERMITTED_CALLS_IN_HALF_OPEN; i++) {
            ingestOnce(meterId);
        }
        assertThat(breaker.getState()).isEqualTo(CircuitBreaker.State.CLOSED);
    }

    // Half-open: re-opens on renewed failure rather than assuming recovery from a stale window.
    @Test
    void postgresBreaker_halfOpen_reopensOnRenewedFailure() throws InterruptedException {
        UUID meterId = UUID.randomUUID();
        when(meterRepository.existsById(meterId))
                .thenThrow(new DataRetrievalFailureException("simulated Postgres failure"));
        CircuitBreaker breaker = circuitBreakerRegistry.circuitBreaker("postgres-existence-check");
        for (int i = 0; i < MINIMUM_NUMBER_OF_CALLS; i++) {
            assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(DataRetrievalFailureException.class);
        }
        assertThat(breaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);

        Thread.sleep(WAIT_DURATION_IN_OPEN_STATE.toMillis() + 100);
        // Still failing -- the dependency never actually recovered.
        for (int i = 0; i < PERMITTED_CALLS_IN_HALF_OPEN; i++) {
            assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(DataRetrievalFailureException.class);
        }
        assertThat(breaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);
    }

    // docs/resilience-scope.md's own explicit requirement: two independent breaker instances, not
    // one shared instance -- a Kafka-only outage must never open the Postgres breaker.
    @Test
    void breakersAreIndependent_kafkaFailuresDoNotOpenPostgresBreaker() {
        UUID meterId = UUID.randomUUID();
        when(meterRepository.existsById(meterId)).thenReturn(true);
        CompletableFuture<SendResult<Object, Object>> failedFuture =
                CompletableFuture.failedFuture(new RuntimeException("simulated Kafka failure"));
        when(kafkaTemplate.send(anyString(), any(), any())).thenReturn(failedFuture);
        CircuitBreaker postgresBreaker = circuitBreakerRegistry.circuitBreaker("postgres-existence-check");
        CircuitBreaker kafkaBreaker = circuitBreakerRegistry.circuitBreaker("kafka-publish");

        for (int i = 0; i < MINIMUM_NUMBER_OF_CALLS; i++) {
            ingestOnce(meterId);
        }

        assertThat(kafkaBreaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);
        assertThat(postgresBreaker.getState()).isEqualTo(CircuitBreaker.State.CLOSED);
    }

    // The reverse direction of the same requirement -- a Postgres-only outage must never open the
    // Kafka breaker (by construction here, since ingest() never reaches the Kafka call at all when
    // the Postgres check throws, but asserted explicitly rather than left implicit).
    @Test
    void breakersAreIndependent_postgresFailuresDoNotOpenKafkaBreaker() {
        UUID meterId = UUID.randomUUID();
        when(meterRepository.existsById(meterId))
                .thenThrow(new DataRetrievalFailureException("simulated Postgres failure"));
        CircuitBreaker postgresBreaker = circuitBreakerRegistry.circuitBreaker("postgres-existence-check");
        CircuitBreaker kafkaBreaker = circuitBreakerRegistry.circuitBreaker("kafka-publish");

        for (int i = 0; i < MINIMUM_NUMBER_OF_CALLS; i++) {
            assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(DataRetrievalFailureException.class);
        }

        assertThat(postgresBreaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);
        assertThat(kafkaBreaker.getState()).isEqualTo(CircuitBreaker.State.CLOSED);
    }

    // docs/resilience-scope.md's "Behavior when open" for the Kafka side specifically, mirroring
    // the Postgres open-state test above.
    @Test
    void kafkaBreaker_open_failsFastWithoutCallingSend() {
        UUID meterId = UUID.randomUUID();
        when(meterRepository.existsById(meterId)).thenReturn(true);
        CompletableFuture<SendResult<Object, Object>> failedFuture =
                CompletableFuture.failedFuture(new RuntimeException("simulated Kafka failure"));
        when(kafkaTemplate.send(anyString(), any(), any())).thenReturn(failedFuture);
        CircuitBreaker kafkaBreaker = circuitBreakerRegistry.circuitBreaker("kafka-publish");

        for (int i = 0; i < MINIMUM_NUMBER_OF_CALLS; i++) {
            ingestOnce(meterId);
        }
        assertThat(kafkaBreaker.getState()).isEqualTo(CircuitBreaker.State.OPEN);

        int sendCallsBeforeOpen = MINIMUM_NUMBER_OF_CALLS;
        assertThatThrownBy(() -> ingestOnce(meterId)).isInstanceOf(CallNotPermittedException.class);
        verify(kafkaTemplate, times(sendCallsBeforeOpen)).send(anyString(), any(), any());
    }
}
