package com.gridmeter.api.config.aws;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.concurrent.atomic.AtomicInteger;

import org.junit.jupiter.api.Test;

import io.lettuce.core.RedisCredentials;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifies the token-caching behaviour itself (regenerate only after TOKEN_CACHE_DURATION
 * elapses, reuse otherwise) via a controllable fake Clock, rather than a real 10-minute sleep --
 * this project's own standing "poll/control time, don't sleep" testing discipline
 * (CLAUDE.md's chaos-test-script lesson), applied here to a unit test instead of an
 * infrastructure script. The signer itself is offline/deterministic (covered by
 * ElastiCacheAuthTokenRequestTest), so this counts calls to the AWS credentials resolver as a
 * proxy for "was a new token actually generated" rather than re-asserting the token's shape.
 */
class AwsElastiCacheCredentialsProviderTest {

    private static final AwsBasicCredentials FAKE_CREDENTIALS =
            AwsBasicCredentials.create("AKIAFAKEACCESSKEY", "fakeSecretAccessKey1234567890");

    @Test
    void reusesTheCachedTokenWithinTheCacheDuration() {
        AtomicInteger resolveCount = new AtomicInteger();
        AwsCredentialsProvider countingAwsCredentials = () -> {
            resolveCount.incrementAndGet();
            return FAKE_CREDENTIALS;
        };
        MutableClock clock = new MutableClock(Instant.parse("2026-09-23T00:00:00Z"));

        AwsElastiCacheCredentialsProvider provider = new AwsElastiCacheCredentialsProvider(
                "app", "grid-meter-redis", "us-east-1", countingAwsCredentials, clock);

        RedisCredentials first = provider.resolveCredentials().block();
        RedisCredentials second = provider.resolveCredentials().block();

        assertThat(resolveCount).hasValue(1);
        assertThat(first.getUsername()).isEqualTo("app");
        assertThat(new String(second.getPassword())).isEqualTo(new String(first.getPassword()));
    }

    @Test
    void regeneratesTheTokenOnceTheCacheDurationElapses() {
        AtomicInteger resolveCount = new AtomicInteger();
        AwsCredentialsProvider countingAwsCredentials = () -> {
            resolveCount.incrementAndGet();
            return FAKE_CREDENTIALS;
        };
        MutableClock clock = new MutableClock(Instant.parse("2026-09-23T00:00:00Z"));

        AwsElastiCacheCredentialsProvider provider = new AwsElastiCacheCredentialsProvider(
                "app", "grid-meter-redis", "us-east-1", countingAwsCredentials, clock);

        provider.resolveCredentials().block();
        clock.advance(AwsElastiCacheCredentialsProvider.TOKEN_CACHE_DURATION.plusSeconds(1));
        provider.resolveCredentials().block();

        assertThat(resolveCount).hasValue(2);
    }

    @Test
    void staysWithinCacheOneSecondBeforeExpiry() {
        AtomicInteger resolveCount = new AtomicInteger();
        AwsCredentialsProvider countingAwsCredentials = () -> {
            resolveCount.incrementAndGet();
            return FAKE_CREDENTIALS;
        };
        MutableClock clock = new MutableClock(Instant.parse("2026-09-23T00:00:00Z"));

        AwsElastiCacheCredentialsProvider provider = new AwsElastiCacheCredentialsProvider(
                "app", "grid-meter-redis", "us-east-1", countingAwsCredentials, clock);

        provider.resolveCredentials().block();
        clock.advance(AwsElastiCacheCredentialsProvider.TOKEN_CACHE_DURATION.minusSeconds(1));
        provider.resolveCredentials().block();

        assertThat(resolveCount).hasValue(1);
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
