package com.gridmeter.api.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;
import com.gridmeter.api.meter.MeterRepository;
import com.gridmeter.api.reading.dto.ReadingRequest;
import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;

/**
 * Pure unit test (Mockito) for the delivery-failure visibility fix -- see ReadingService.ingest()'s
 * own comment. Deliberately not a Testcontainers-based test forcing a real 120s
 * delivery.timeout.ms wait: mocking the returned Future's outcome is faster and just as decisive
 * for verifying the counter/log side effects, which don't depend on real Kafka timing.
 */
class ReadingServiceTest {

    private MeterRepository meterRepository;
    private KafkaTemplate<Object, Object> kafkaTemplate;
    private SimpleMeterRegistry meterRegistry;
    private ReadingService readingService;
    private ListAppender<ILoggingEvent> logAppender;

    @BeforeEach
    void setUp() {
        meterRepository = mock(MeterRepository.class);
        kafkaTemplate = mock(KafkaTemplate.class);
        meterRegistry = new SimpleMeterRegistry();
        readingService = new ReadingService(
                mock(ReadingRepository.class), meterRepository, kafkaTemplate, "readings", meterRegistry);

        logAppender = new ListAppender<>();
        logAppender.start();
        ((Logger) LoggerFactory.getLogger(ReadingService.class)).addAppender(logAppender);
    }

    @AfterEach
    void tearDown() {
        ((Logger) LoggerFactory.getLogger(ReadingService.class)).detachAppender(logAppender);
    }

    @Test
    void ingest_kafkaDeliveryFails_incrementsCounterAndLogsWithRecoveryContext() {
        UUID meterId = UUID.randomUUID();
        Instant readingTimestamp = Instant.parse("2026-08-28T12:00:00Z");
        BigDecimal value = new BigDecimal("42.5");
        when(meterRepository.existsById(meterId)).thenReturn(true);
        CompletableFuture<SendResult<Object, Object>> failedFuture =
                CompletableFuture.failedFuture(new RuntimeException("Expiring record(s): delivery.timeout.ms exceeded"));
        when(kafkaTemplate.send(anyString(), any(), any())).thenReturn(failedFuture);

        ReadingEvent event = readingService.ingest(new ReadingRequest(meterId, readingTimestamp, value));

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

        readingService.ingest(new ReadingRequest(meterId, Instant.now(), BigDecimal.TEN));

        // The counter is registered eagerly in the constructor (so it always appears on
        // /actuator/prometheus, even at zero, rather than only after the first-ever failure) --
        // asserting count=0 here, not that the counter is absent.
        assertThat(meterRegistry.get("reading.delivery.failures").counter().count()).isEqualTo(0.0);
        assertThat(logAppender.list).noneMatch(logEvent -> logEvent.getLevel().toString().equals("ERROR"));
    }
}
