package com.gridmeter.api.config.gcp;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.function.Supplier;

import io.lettuce.core.RedisCredentials;
import io.lettuce.core.RedisCredentialsProvider;
import reactor.core.publisher.Mono;

/**
 * Lettuce {@link RedisCredentialsProvider} for Memorystore for Valkey IAM auth: resolves to the
 * literal username {@code "default"} plus a GCP OAuth2 access token used as the AUTH password -
 * matching Google Cloud's own official Java/Lettuce IAM-auth reference sample exactly (confirmed
 * 2026-09-24 against the real docs page, not a summary), down to the username and the fact that
 * the token comes from an explicit {@code IamCredentialsClient.generateAccessToken()}
 * self-impersonation call rather than the pod's ambient Workload Identity credentials directly.
 * <p>
 * The actual gRPC call is injected as a {@link Supplier} (see {@link GcpRedisConfig}) rather than
 * made directly here, so the caching/expiry logic below is unit-testable without a live network
 * call - the same separation AWS's {@code AwsElastiCacheCredentialsProvider} uses.
 * <p>
 * Tokens requested with a 1-hour lifetime (GCP's default maximum for generateAccessToken without
 * extended-lifetime org policy setup); cached for 50 minutes to leave a 10-minute refresh margin,
 * the same absolute margin AWS's provider uses.
 */
class GcpMemorystoreCredentialsProvider implements RedisCredentialsProvider {

    static final String USERNAME = "default";
    static final Duration TOKEN_CACHE_DURATION = Duration.ofMinutes(50);

    private final Supplier<String> accessTokenFetcher;
    private final Clock clock;

    private String cachedToken;
    private Instant cachedAt = Instant.MIN;

    GcpMemorystoreCredentialsProvider(Supplier<String> accessTokenFetcher, Clock clock) {
        this.accessTokenFetcher = accessTokenFetcher;
        this.clock = clock;
    }

    @Override
    public Mono<RedisCredentials> resolveCredentials() {
        return Mono.just(RedisCredentials.just(USERNAME, currentToken()));
    }

    // synchronized: Lettuce may resolve credentials concurrently across multiple connections
    // (reconnects, pool growth) - the cache read/regenerate/write must be atomic.
    private synchronized String currentToken() {
        Instant now = clock.instant();
        if (cachedToken == null || Duration.between(cachedAt, now).compareTo(TOKEN_CACHE_DURATION) >= 0) {
            cachedToken = accessTokenFetcher.get();
            cachedAt = now;
        }
        return cachedToken;
    }
}
