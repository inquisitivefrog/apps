package com.gridmeter.api.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gridmeter.api.meter.MeterRepository;
import com.gridmeter.api.reading.dto.ReadingRequest;
import io.github.resilience4j.circuitbreaker.CircuitBreakerRegistry;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

/**
 * Pure unit test (Mockito) for docs/idempotency-scope.md's Redis fast path (a) in isolation, per
 * that doc's own "Testing implications" section — kept as a separate class from
 * {@link ReadingServiceTest} (scoped to the unrelated delivery-failure-visibility fix) so this
 * feature's results are reportable on their own, not folded into another test's output.
 */
class ReadingServiceIdempotencyTest {

    private MeterRepository meterRepository;
    private KafkaTemplate<Object, Object> kafkaTemplate;
    private ValueOperations<String, Object> valueOperations;
    private ReadingService readingService;

    @BeforeEach
    void setUp() {
        meterRepository = mock(MeterRepository.class);
        kafkaTemplate = mock(KafkaTemplate.class);
        RedisTemplate<String, Object> redisTemplate = mock(RedisTemplate.class);
        valueOperations = mock(ValueOperations.class);
        when(redisTemplate.opsForValue()).thenReturn(valueOperations);
        when(kafkaTemplate.send(anyString(), any(), any()))
                .thenReturn(CompletableFuture.completedFuture(mock(SendResult.class)));
        when(meterRepository.existsById(any())).thenReturn(true);

        // ofDefaults() is fine here -- this test class is scoped to idempotency behavior, not
        // circuit-breaker behavior (see ReadingServiceTest for that), and none of these tests
        // drive enough failing calls to trip a breaker either way.
        readingService = new ReadingService(
                mock(ReadingRepository.class),
                meterRepository,
                kafkaTemplate,
                redisTemplate,
                "readings",
                new SimpleMeterRegistry(),
                CircuitBreakerRegistry.ofDefaults());
    }

    private ReadingRequest anyRequest() {
        return new ReadingRequest(UUID.randomUUID(), Instant.now(), BigDecimal.TEN);
    }

    @Test
    void newKey_setnxSucceeds_publishesToKafka() {
        when(valueOperations.setIfAbsent(anyString(), any(), any(Duration.class))).thenReturn(true);

        readingService.ingest(anyRequest(), "key-" + UUID.randomUUID());

        verify(kafkaTemplate, times(1)).send(anyString(), any(), any());
    }

    @Test
    void duplicateKey_setnxFails_doesNotRepublishToKafkaButStillReturns201Shape() {
        when(valueOperations.setIfAbsent(anyString(), any(), any(Duration.class))).thenReturn(false);
        ReadingRequest request = anyRequest();

        ReadingEvent event = readingService.ingest(request, "duplicate-key");

        verify(kafkaTemplate, never()).send(anyString(), any(), any());
        // ingest() still returns a well-formed ReadingEvent (echoed request data, per
        // idempotency-scope.md), which is what lets the controller still respond 201 rather than
        // erroring on a duplicate -- duplicates are normal traffic, not a failure.
        assertThat(event.meterId()).isEqualTo(request.meterId());
        assertThat(event.value()).isEqualByComparingTo(request.value());
    }

    @Test
    void redisThrowsOnSetnx_failsOpen_stillPublishesToKafka() {
        when(valueOperations.setIfAbsent(anyString(), any(), any(Duration.class)))
                .thenThrow(new DataAccessResourceFailureException("Redis unavailable"));

        readingService.ingest(anyRequest(), "key-during-redis-outage");

        // The actual proof this degrades correctly: publish still happens even though the Redis
        // check itself blew up, not merely that the code path compiles.
        verify(kafkaTemplate, times(1)).send(anyString(), any(), any());
    }
}
