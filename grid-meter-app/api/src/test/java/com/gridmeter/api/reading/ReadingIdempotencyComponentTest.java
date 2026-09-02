package com.gridmeter.api.reading;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

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
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;

/**
 * Component tests (real Postgres/Kafka/Redis via Testcontainers) for docs/idempotency-scope.md's
 * two-layer design, kept separate from {@link ReadingComponentTest} (which exercises the general
 * ingest path, not idempotency specifically) so this feature's results are reportable on their
 * own. Per that doc's "Testing implications" section: the "Redis stopped mid-test" component case
 * is deliberately NOT included here -- {@link ComponentTestSupport}'s Redis container is a
 * JVM-wide singleton shared by every component test class, so pausing/stopping it mid-test would
 * risk breaking every other test class's Redis access for the rest of the suite run. The Redis
 * fail-open behavior itself is already directly proven in isolation by
 * {@link ReadingServiceIdempotencyTest#redisThrowsOnSetnx_failsOpen_stillPublishesToKafka}; adding
 * a real-outage variant here was judged not worth that shared-infrastructure risk.
 */
class ReadingIdempotencyComponentTest extends ComponentTestSupport {

    @Autowired
    private ReadingService readingService;

    @Autowired
    private MeterService meterService;

    private Meter createMeter() {
        return meterService.create(
                new MeterRequest("MTR-" + UUID.randomUUID(), "Test Location", MeterStatus.ACTIVE,
                        Instant.parse("2026-01-15T00:00:00Z")),
                com.gridmeter.api.customer.Customer.DEFAULT_ID);
    }

    private int countReadingsForMeter(UUID meterId) {
        return readingService
                .search(meterId, null, null, null, null,
                        PageRequest.of(0, 100, Sort.by("readingTimestamp").descending()))
                .getContent()
                .size();
    }

    @Test
    void duplicateKey_sameRequestSentTwice_exactlyOneRowPersisted() {
        Meter meter = createMeter();
        ReadingRequest request = new ReadingRequest(meter.getId(), Instant.now(), new BigDecimal("11.000"));
        String idempotencyKey = UUID.randomUUID().toString();

        readingService.ingest(request, idempotencyKey);
        readingService.ingest(request, idempotencyKey);

        // during(): the count must not just reach 1, it must STAY at 1 across the whole poll
        // window -- catches a duplicate row that lands late (e.g. from the second Kafka message
        // still being consumed) that a single one-shot check right after reaching 1 could miss.
        await().atMost(Duration.ofSeconds(15))
                .pollInterval(Duration.ofMillis(200))
                .during(Duration.ofSeconds(3))
                .untilAsserted(() -> assertThat(countReadingsForMeter(meter.getId())).isEqualTo(1));
    }

    @Test
    void concurrentIdenticalRequests_dbConstraintIsTheRealBackstop() throws InterruptedException {
        Meter meter = createMeter();
        ReadingRequest request = new ReadingRequest(meter.getId(), Instant.now(), new BigDecimal("22.000"));
        String idempotencyKey = UUID.randomUUID().toString();

        // Two threads race to submit the identical key at the same instant -- a CountDownLatch
        // lines them up so both cross the SETNX check as close together as possible, rather than
        // relying on thread scheduling alone to create the race. This is the scenario (a)'s Redis
        // check alone cannot fully guarantee against; only (b)'s unique DB constraint can.
        ExecutorService executor = Executors.newFixedThreadPool(2);
        CountDownLatch startLatch = new CountDownLatch(1);
        try {
            for (int i = 0; i < 2; i++) {
                executor.submit(() -> {
                    try {
                        startLatch.await();
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                    readingService.ingest(request, idempotencyKey);
                });
            }
            startLatch.countDown();
        } finally {
            executor.shutdown();
            assertThat(executor.awaitTermination(10, TimeUnit.SECONDS)).isTrue();
        }

        await().atMost(Duration.ofSeconds(15))
                .pollInterval(Duration.ofMillis(200))
                .during(Duration.ofSeconds(3))
                .untilAsserted(() -> assertThat(countReadingsForMeter(meter.getId())).isEqualTo(1));
    }
}
