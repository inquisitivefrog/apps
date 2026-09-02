package com.gridmeter.api.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.awaitility.Awaitility.await;

import com.gridmeter.api.common.ResourceNotFoundException;
import com.gridmeter.api.customer.Customer;
import com.gridmeter.api.customer.CustomerRepository;
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

    @Autowired
    private CustomerRepository customerRepository;

    private Meter createMeter() {
        return createMeter(Customer.DEFAULT_ID);
    }

    private Meter createMeter(UUID customerId) {
        return meterService.create(new MeterRequest(
                "MTR-" + UUID.randomUUID(), "Test Location", MeterStatus.ACTIVE,
                Instant.parse("2026-01-15T00:00:00Z")), customerId);
    }

    private UUID createOtherCustomer() {
        Instant now = Instant.now();
        return customerRepository.save(Customer.builder()
                .id(UUID.randomUUID())
                .name("Other Customer " + UUID.randomUUID())
                .createdAt(now)
                .updatedAt(now)
                .build()).getId();
    }

    // ignoreExceptions() matters here, not just style: findById() throws ResourceNotFoundException
    // (rather than returning null) before the consumer has caught up, and Awaitility does NOT catch
    // exceptions thrown by the polled supplier by default -- without this, the very first poll that
    // loses the race against consumer lag fails the test immediately instead of retrying for the
    // full atMost window. Latent since this helper was first written; only surfaced once a test
    // (search_returnsReadingsAcrossAllCustomers...) ingested two readings back-to-back under a full
    // -suite load, making that race actually losable.
    private Reading awaitPersisted(UUID readingId) {
        return await().atMost(Duration.ofSeconds(10))
                .pollInterval(Duration.ofMillis(200))
                .ignoreExceptions()
                .until(() -> readingService.findById(readingId), r -> r != null);
    }

    @Test
    void ingest_consumerPersistsToPostgresAndCachesLatestInRedis() {
        Meter meter = createMeter();
        Instant readingTimestamp = Instant.parse("2026-08-11T06:00:00Z");
        ReadingEvent event = readingService.ingest(
                new ReadingRequest(meter.getId(), readingTimestamp, new BigDecimal("42.500")),
                UUID.randomUUID().toString());

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

        assertThatThrownBy(() -> readingService.ingest(request, UUID.randomUUID().toString()))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void search_filtersByMeterIdAndValueRange() {
        Meter meter = createMeter();
        ReadingEvent low = readingService.ingest(
                new ReadingRequest(meter.getId(), Instant.parse("2026-08-01T00:00:00Z"), new BigDecimal("10.000")),
                UUID.randomUUID().toString());
        ReadingEvent high = readingService.ingest(
                new ReadingRequest(meter.getId(), Instant.parse("2026-08-02T00:00:00Z"), new BigDecimal("90.000")),
                UUID.randomUUID().toString());
        awaitPersisted(low.id());
        awaitPersisted(high.id());

        Page<Reading> result = readingService.search(
                meter.getId(), null, null, new BigDecimal("50.000"), null,
                PageRequest.of(0, 20, Sort.by("readingTimestamp").descending()));

        assertThat(result.getContent()).extracting(Reading::getId).containsExactly(high.id());
    }

    // docs/multi-tenancy-scope.md, "Testing implications": search() takes no customerId filter at
    // all -- this pass adds customerId to Meter/User but deliberately does not enforce isolation on
    // reads, and this test documents that as real, tested behavior rather than an assumption. Uses
    // a distinctive value bracket (not meterId) to isolate these two rows from the millions of
    // pre-existing readings in this dev/test dataset, precisely BECAUSE meterId is intentionally
    // left unset here -- that's what proves the search spans meters/customers, not just one meter.
    @Test
    void search_returnsReadingsAcrossAllCustomers_documentingCurrentNonIsolation() {
        BigDecimal distinctiveValue = new BigDecimal("918273.645");
        Meter defaultCustomerMeter = createMeter();
        Meter otherCustomerMeter = createMeter(createOtherCustomer());
        ReadingEvent defaultCustomerReading = readingService.ingest(new ReadingRequest(
                defaultCustomerMeter.getId(), Instant.parse("2026-08-03T00:00:00Z"), distinctiveValue),
                UUID.randomUUID().toString());
        ReadingEvent otherCustomerReading = readingService.ingest(new ReadingRequest(
                otherCustomerMeter.getId(), Instant.parse("2026-08-04T00:00:00Z"), distinctiveValue),
                UUID.randomUUID().toString());
        awaitPersisted(defaultCustomerReading.id());
        awaitPersisted(otherCustomerReading.id());

        Page<Reading> result = readingService.search(
                null, null, null, distinctiveValue, distinctiveValue,
                PageRequest.of(0, 20, Sort.by("readingTimestamp").descending()));

        assertThat(result.getContent())
                .extracting(Reading::getId)
                .containsExactlyInAnyOrder(defaultCustomerReading.id(), otherCustomerReading.id());
        assertThat(result.getContent())
                .extracting(Reading::getMeterId)
                .containsExactlyInAnyOrder(defaultCustomerMeter.getId(), otherCustomerMeter.getId());
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
                new ReadingRequest(meter.getId(), Instant.now(), BigDecimal.ONE), UUID.randomUUID().toString());
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
