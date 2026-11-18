package com.gridmeter.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.anyDouble;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import io.micrometer.core.instrument.simple.SimpleMeterRegistry;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataAccessResourceFailureException;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.data.redis.core.ZSetOperations;

/**
 * Pure unit test (Mockito) for {@link ActiveUserTracker}'s failure handling: a Redis outage must
 * never fail a login, and must show as a gap (NaN) on the gauge rather than a stale number.
 * The real-Redis counting behavior is covered by {@link ActiveUserTrackerComponentTest}.
 */
class ActiveUserTrackerTest {

    private static final Instant NOW = Instant.parse("2026-11-17T12:00:00Z");
    private static final Duration WINDOW = Duration.ofHours(1);

    private ZSetOperations<String, String> zSet;
    private SimpleMeterRegistry meterRegistry;
    private ActiveUserTracker tracker;

    @BeforeEach
    void setUp() {
        StringRedisTemplate redis = mock(StringRedisTemplate.class);
        zSet = mock(ZSetOperations.class);
        when(redis.opsForZSet()).thenReturn(zSet);
        meterRegistry = new SimpleMeterRegistry();
        tracker = new ActiveUserTracker(redis, WINDOW, meterRegistry, Clock.fixed(NOW, ZoneOffset.UTC));
    }

    private double gauge() {
        return meterRegistry.get("auth.active.users").gauge().value();
    }

    @Test
    void gauge_isNaNBeforeFirstRefresh() {
        assertThat(gauge()).isNaN();
    }

    @Test
    void refresh_countsOnlyLoginsInsideTheTokenLifetime() {
        long windowStart = NOW.minus(WINDOW).toEpochMilli();
        when(zSet.count(ActiveUserTracker.KEY, windowStart, Double.POSITIVE_INFINITY)).thenReturn(3L);

        tracker.refresh();

        assertThat(gauge()).isEqualTo(3.0);
    }

    @Test
    void recordLogin_redisDown_doesNotThrow() {
        when(zSet.add(anyString(), anyString(), anyDouble()))
                .thenThrow(new DataAccessResourceFailureException("redis down"));

        assertThatCode(() -> tracker.recordLogin("demo")).doesNotThrowAnyException();
    }

    @Test
    void recordLogin_prunesEntriesOlderThanTheTokenLifetime() {
        tracker.recordLogin("demo");

        verify(zSet).add(ActiveUserTracker.KEY, "demo", NOW.toEpochMilli());
        verify(zSet).removeRangeByScore(
                eq(ActiveUserTracker.KEY), eq(Double.NEGATIVE_INFINITY), eq((double) NOW.minus(WINDOW).toEpochMilli()));
    }

    @Test
    void refresh_redisDown_reportsNaNInsteadOfTheLastValue() {
        long windowStart = NOW.minus(WINDOW).toEpochMilli();
        when(zSet.count(ActiveUserTracker.KEY, windowStart, Double.POSITIVE_INFINITY))
                .thenReturn(5L)
                .thenThrow(new DataAccessResourceFailureException("redis down"));

        tracker.refresh();
        assertThat(gauge()).isEqualTo(5.0);

        tracker.refresh();
        assertThat(gauge()).isNaN();
    }
}
