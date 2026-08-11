package com.gridmeter.api.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.awaitility.Awaitility.await;

import com.gridmeter.api.common.ResourceNotFoundException;
import com.gridmeter.api.meter.Meter;
import com.gridmeter.api.meter.MeterService;
import com.gridmeter.api.meter.MeterStatus;
import com.gridmeter.api.meter.dto.MeterRequest;
import com.gridmeter.api.reading.dto.ReadingRequest;
import com.gridmeter.api.support.ComponentTestSupport;
import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.redis.core.RedisTemplate;

/**
 * Component tests for the full ingest path: {@link ReadingService} publishes to Kafka, {@link
 * ReadingEventConsumer} consumes it and writes to Postgres + Redis. Assertions on the consumer side
 * poll with Awaitility rather than sleep, since that write happens asynchronously on the Kafka
 * listener thread, not within the calling test thread. No PUT-rejection test here — that's an
 * HTTP-level (405) concern for the planned REST Assured API test layer, not this service-level
 * component suite (see docs/testing-strategy.md).
 */
class ReadingComponentTest extends ComponentTestSupport {

    @Autowired
    private ReadingService readingService;

    @Autowired
    private MeterService meterService;

    @Autowired
    private RedisTemplate<String, Object> redisTemplate;

    private Meter createMeter() {
        return meterService.create(new MeterRequest(
                "MTR-" + UUID.randomUUID(), "Test Location", MeterStatus.ACTIVE,
                Instant.parse("2026-01-15T00:00:00Z")));
    }

    private Reading awaitPersisted(UUID readingId) {
        return await().atMost(Duration.ofSeconds(10))
                .pollInterval(Duration.ofMillis(200))
                .until(() -> readingService.findById(readingId), r -> r != null);
    }

    @Test
    void ingest_consumerPersistsToPostgresAndCachesLatestInRedis() {
        Meter meter = createMeter();
        Instant readingTimestamp = Instant.parse("2026-08-11T06:00:00Z");
        ReadingEvent event = readingService.ingest(
                new ReadingRequest(meter.getId(), readingTimestamp, new BigDecimal("42.500")));

        Reading persisted = awaitPersisted(event.id());
        assertThat(persisted.getMeterId()).isEqualTo(meter.getId());
        assertThat(persisted.getValue()).isEqualByComparingTo("42.500");
        assertThat(persisted.getReadingTimestamp()).isEqualTo(readingTimestamp);

        String key = "reading:latest:" + meter.getId();
        await().atMost(Duration.ofSeconds(10))
                .pollInterval(Duration.ofMillis(200))
                .untilAsserted(() -> assertThat(redisTemplate.opsForValue().get(key)).isNotNull());

        LatestReading cached = (LatestReading) redisTemplate.opsForValue().get(key);
        assertThat(cached.meterId()).isEqualTo(meter.getId());
        assertThat(cached.value()).isEqualByComparingTo("42.500");
    }

    @Test
    void ingest_unknownMeterId_throwsNotFound() {
        ReadingRequest request = new ReadingRequest(UUID.randomUUID(), Instant.now(), BigDecimal.TEN);

        assertThatThrownBy(() -> readingService.ingest(request))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void search_filtersByMeterIdAndValueRange() {
        Meter meter = createMeter();
        ReadingEvent low = readingService.ingest(
                new ReadingRequest(meter.getId(), Instant.parse("2026-08-01T00:00:00Z"), new BigDecimal("10.000")));
        ReadingEvent high = readingService.ingest(
                new ReadingRequest(meter.getId(), Instant.parse("2026-08-02T00:00:00Z"), new BigDecimal("90.000")));
        awaitPersisted(low.id());
        awaitPersisted(high.id());

        Page<Reading> result = readingService.search(
                meter.getId(), null, null, new BigDecimal("50.000"), null,
                PageRequest.of(0, 20, Sort.by("readingTimestamp").descending()));

        assertThat(result.getContent()).extracting(Reading::getId).containsExactly(high.id());
    }

    @Test
    void findById_unknownId_throwsNotFound() {
        assertThatThrownBy(() -> readingService.findById(UUID.randomUUID()))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void delete_removesReading() {
        Meter meter = createMeter();
        ReadingEvent event = readingService.ingest(
                new ReadingRequest(meter.getId(), Instant.now(), BigDecimal.ONE));
        awaitPersisted(event.id());

        readingService.delete(event.id());

        assertThatThrownBy(() -> readingService.findById(event.id()))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void delete_unknownId_throwsNotFound() {
        assertThatThrownBy(() -> readingService.delete(UUID.randomUUID()))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
