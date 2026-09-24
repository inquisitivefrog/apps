package com.gridmeter.api.config.gcp;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.Test;

import io.lettuce.core.RedisCredentials;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifies the token-caching behaviour itself (regenerate only after TOKEN_CACHE_DURATION
 * elapses, reuse otherwise) via a controllable fake Clock, this project's own standing
 * "poll/control time, don't sleep" testing discipline. The real
 * IamCredentialsClient.generateAccessToken() call is a live gRPC call, not offline-testable the
 * way AWS's SigV4 signing was - so this counts calls to a stub token-fetcher Supplier instead,
 * the same separation-of-concerns AwsElastiCacheCredentialsProviderTest uses for its
 * AwsCredentialsProvider stub.
 */
class GcpMemorystoreCredentialsProviderTest {

    @Test
    void resolvesTheLiteralDefaultUsername() {
        MutableClock clock = new MutableClock(Instant.parse("2026-09-24T00:00:00Z"));
        GcpMemorystoreCredentialsProvider provider =
                new GcpMemorystoreCredentialsProvider(() -> "fake-token", clock);

        RedisCredentials credentials = provider.resolveCredentials().block();

        assertThat(credentials.getUsername()).isEqualTo("default");
        assertThat(new String(credentials.getPassword())).isEqualTo("fake-token");
    }

    @Test
    void reusesTheCachedTokenWithinTheCacheDuration() {
        AtomicInteger fetchCount = new AtomicInteger();
        MutableClock clock = new MutableClock(Instant.parse("2026-09-24T00:00:00Z"));
        GcpMemorystoreCredentialsProvider provider = new GcpMemorystoreCredentialsProvider(
                () -> "token-" + fetchCount.incrementAndGet(), clock);

        RedisCredentials first = provider.resolveCredentials().block();
        RedisCredentials second = provider.resolveCredentials().block();

        assertThat(fetchCount).hasValue(1);
        assertThat(new String(second.getPassword())).isEqualTo(new String(first.getPassword()));
    }

    @Test
    void regeneratesTheTokenOnceTheCacheDurationElapses() {
        AtomicInteger fetchCount = new AtomicInteger();
        MutableClock clock = new MutableClock(Instant.parse("2026-09-24T00:00:00Z"));
        GcpMemorystoreCredentialsProvider provider = new GcpMemorystoreCredentialsProvider(
                () -> "token-" + fetchCount.incrementAndGet(), clock);

        provider.resolveCredentials().block();
        clock.advance(GcpMemorystoreCredentialsProvider.TOKEN_CACHE_DURATION.plusSeconds(1));
        provider.resolveCredentials().block();

        assertThat(fetchCount).hasValue(2);
    }

    @Test
    void staysWithinCacheOneSecondBeforeExpiry() {
        AtomicInteger fetchCount = new AtomicInteger();
        MutableClock clock = new MutableClock(Instant.parse("2026-09-24T00:00:00Z"));
        GcpMemorystoreCredentialsProvider provider = new GcpMemorystoreCredentialsProvider(
                () -> "token-" + fetchCount.incrementAndGet(), clock);

        provider.resolveCredentials().block();
        clock.advance(GcpMemorystoreCredentialsProvider.TOKEN_CACHE_DURATION.minusSeconds(1));
        provider.resolveCredentials().block();

        assertThat(fetchCount).hasValue(1);
    }

    /** A fixed-instant Clock whose instant can be advanced on demand, for cache-expiry tests. */
    private static final class MutableClock extends Clock {
        private Instant instant;

        MutableClock(Instant instant) {
            this.instant = instant;
        }

        void advance(Duration duration) {
            instant = instant.plus(duration);
        }

        @Override
        public Instant instant() {
            return instant;
        }

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            throw new UnsupportedOperationException();
        }
    }
}
