package com.gridmeter.api.config.aws;

import java.time.Clock;
import java.time.Duration;
import java.time.Instant;

import io.lettuce.core.RedisCredentials;
import io.lettuce.core.RedisCredentialsProvider;
import reactor.core.publisher.Mono;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;

/**
 * Lettuce {@link RedisCredentialsProvider} for ElastiCache IAM auth: resolves to the
 * IAM-auth-enabled Redis user (terraform/aws/elasticache-iam-auth.tf's aws_elasticache_user.app)
 * plus a SigV4-signed token used as the AUTH password.
 * <p>
 * Uses the one-shot {@link #resolveCredentials()} variant, not Lettuce's streaming
 * {@code credentials()}/Flux variant, matching AWS's own reference implementation
 * (aws-samples/elasticache-iam-auth-demo-app's RedisIAMAuthCredentialsProvider, confirmed
 * 2026-09-23) rather than the theoretically-available alternative — Lettuce calls
 * {@code resolveCredentials()} on every new/reconnecting connection, so a cached, self-refreshing
 * token behind that one method is sufficient without needing a push-based stream.
 * <p>
 * Tokens are valid 15 minutes (an ElastiCache/IAM-auth constant, not configurable); cached for 10
 * to leave a safe refresh margin, same duration AWS's own reference implementation uses.
 */
class AwsElastiCacheCredentialsProvider implements RedisCredentialsProvider {

    static final Duration TOKEN_CACHE_DURATION = Duration.ofMinutes(10);

    private final String userId;
    private final AwsCredentialsProvider awsCredentialsProvider;
    private final ElastiCacheAuthTokenRequest tokenRequest;
    private final Clock clock;

    private String cachedToken;
    private Instant cachedAt = Instant.MIN;

    AwsElastiCacheCredentialsProvider(String userId, String replicationGroupId, String region,
            AwsCredentialsProvider awsCredentialsProvider, Clock clock) {
        this.userId = userId;
        this.awsCredentialsProvider = awsCredentialsProvider;
        this.tokenRequest = new ElastiCacheAuthTokenRequest(userId, replicationGroupId, region);
        this.clock = clock;
    }

    @Override
    public Mono<RedisCredentials> resolveCredentials() {
        return Mono.just(RedisCredentials.just(userId, currentToken()));
    }

    // synchronized: Lettuce may resolve credentials concurrently across multiple connections
    // (reconnects, pool growth) — the cache read/regenerate/write must be atomic, not just the
    // individual field accesses.
    private synchronized String currentToken() {
        Instant now = clock.instant();
        if (cachedToken == null || Duration.between(cachedAt, now).compareTo(TOKEN_CACHE_DURATION) >= 0) {
            cachedToken = tokenRequest.toSignedRequestUri(awsCredentialsProvider.resolveCredentials());
            cachedAt = now;
        }
        return cachedToken;
    }
}
