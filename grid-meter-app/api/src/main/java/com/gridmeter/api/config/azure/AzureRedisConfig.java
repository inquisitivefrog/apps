package com.gridmeter.api.config.azure;

import java.util.Collections;
import java.util.Set;

import org.springframework.boot.data.redis.autoconfigure.LettuceClientConfigurationBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.data.redis.connection.RedisConfiguration;
import org.springframework.data.redis.connection.lettuce.RedisCredentialsProviderFactory;

import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;

import io.lettuce.authx.TokenBasedRedisCredentialsProvider;
import redis.clients.authentication.entraid.AzureTokenAuthConfigBuilder;
import redis.clients.authentication.core.TokenAuthConfig;

/**
 * Wires Managed Redis's Entra ID auth into the auto-configured LettuceConnectionFactory, the same
 * {@link LettuceClientConfigurationBuilderCustomizer} extension point AWS's/GCP's own
 * {@code AwsRedisConfig}/{@code GcpRedisConfig} use.
 * <p>
 * Genuinely simpler than AWS/GCP: Lettuce itself already ships
 * {@link TokenBasedRedisCredentialsProvider} (confirmed 2026-09-24 via javap against the real
 * installed lettuce-core jar - "Lettuce 6.6.0 introduces built-in support" per Redis's own docs),
 * with native background token caching/renewal. There is no custom credentials-provider class in
 * this package at all - just the wiring below, backed by
 * {@code redis.clients.authentication:redis-authx-entraid}'s Azure-specific
 * {@link AzureTokenAuthConfigBuilder} (confirmed via its real source to accept any
 * {@link DefaultAzureCredential} directly, not the docs page's narrower "managed identity"
 * builder path, which is IMDS-oriented and not confirmed compatible with AKS Workload Identity
 * Federation).
 * <p>
 * No app-level identity configuration is needed either: {@link DefaultAzureCredential}'s own
 * documented fallback chain includes {@code WorkloadIdentityCredential}, which reads the
 * {@code AZURE_CLIENT_ID}/{@code AZURE_TENANT_ID}/{@code AZURE_FEDERATED_TOKEN_FILE}/
 * {@code AZURE_AUTHORITY_HOST} env vars AKS's Workload Identity webhook injects automatically onto
 * a pod whose ServiceAccount carries the {@code azure.workload.identity/client-id} annotation and
 * whose pod template carries the {@code azure.workload.identity/use: "true"} label
 * (k8s/api-azure.yaml) - a genuine difference from AWS's role ARN/GCP's service account email,
 * both of which had to be threaded through as explicit env vars.
 * <p>
 * Gated to "cloud-azure" specifically, not the shared "cloud" profile every cloud deployment
 * activates (see application.yml's cloud profile block): k8s/api-azure.yaml activates both
 * ("cloud,cloud-azure") so this bean tree loads only there.
 */
@Configuration
@Profile("cloud-azure")
public class AzureRedisConfig {

    // Matches redis-authx-entraid's own AzureTokenAuthConfigBuilder.DEFAULT_SCOPES - declared
    // explicitly rather than relying on that default, per this project's standing
    // declare-defaults-explicitly discipline.
    private static final Set<String> REDIS_SCOPE = Collections.singleton("https://redis.azure.com/.default");

    @Bean
    DefaultAzureCredential defaultAzureCredential() {
        return new DefaultAzureCredentialBuilder().build();
    }

    @Bean(destroyMethod = "close")
    TokenBasedRedisCredentialsProvider tokenBasedRedisCredentialsProvider(DefaultAzureCredential credential)
            throws Exception {
        TokenAuthConfig config;
        try (AzureTokenAuthConfigBuilder builder = AzureTokenAuthConfigBuilder.builder()) {
            config = builder.defaultAzureCredential(credential).scopes(REDIS_SCOPE).build();
        }
        return TokenBasedRedisCredentialsProvider.create(config);
    }

    @Bean
    LettuceClientConfigurationBuilderCustomizer azureManagedRedisLettuceCustomizer(
            TokenBasedRedisCredentialsProvider credentialsProvider) {
        // RedisCredentialsProviderFactory's methods are both `default`, so it isn't a true
        // functional interface - same real compile-time finding AWS's/GCP's own *RedisConfig
        // classes already made ("no abstract method found"). Sentinel is out of scope here for
        // the same reason as AWS/GCP (Managed Redis has no Sentinel process to discover).
        RedisCredentialsProviderFactory credentialsProviderFactory = new RedisCredentialsProviderFactory() {
            @Override
            public io.lettuce.core.RedisCredentialsProvider createCredentialsProvider(
                    RedisConfiguration redisConfiguration) {
                return credentialsProvider;
            }
        };

        // useSsl(): Managed Redis is TLS-only (rediscache.tf's default_database block has no
        // plaintext option), same posture as AWS's/GCP's own Redis products.
        return builder -> builder.useSsl().and().redisCredentialsProviderFactory(credentialsProviderFactory);
    }
}
