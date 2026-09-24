package com.gridmeter.api.config.aws;

import java.time.Clock;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.data.redis.autoconfigure.LettuceClientConfigurationBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.data.redis.connection.RedisConfiguration;
import org.springframework.data.redis.connection.lettuce.RedisCredentialsProviderFactory;

import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider;

/**
 * Wires ElastiCache IAM auth into the auto-configured LettuceConnectionFactory: a
 * {@link LettuceClientConfigurationBuilderCustomizer} bean is Spring Boot's own supported
 * extension point for this (confirmed 2026-09-23 via javap against the real installed
 * spring-boot-data-redis-4.1.0/spring-data-redis-4.1.0 jars) — no need to replace
 * RedisStandaloneConfiguration or LettuceConnectionFactory wholesale.
 * <p>
 * Gated to "cloud-aws" specifically, not the shared "cloud" profile every cloud deployment
 * activates (see application.yml's cloud profile block): k8s/api-aws.yaml activates both
 * ("cloud,cloud-aws") so this bean tree loads only there, leaving GCP's/Azure's still-pending
 * equivalent credential-provider work free to use their own "cloud-gcp"/"cloud-azure" profiles
 * later without colliding here.
 */
@Configuration
@Profile("cloud-aws")
public class AwsRedisConfig {

    @Value("${GRID_METER_AWS_ELASTICACHE_USER_ID}")
    private String elastiCacheUserId;

    @Value("${GRID_METER_AWS_ELASTICACHE_REPLICATION_GROUP_ID}")
    private String replicationGroupId;

    @Value("${AWS_REGION}")
    private String awsRegion;

    @Bean
    AwsCredentialsProvider awsCredentialsProvider() {
        // IRSA-aware out of the box: picks up the AWS_WEB_IDENTITY_TOKEN_FILE/AWS_ROLE_ARN env
        // vars EKS's Pod Identity webhook injects onto a correctly-annotated ServiceAccount
        // (k8s/api-aws.yaml's serviceAccountName, still pending), same as any other AWS SDK v2
        // client — no manual STS AssumeRoleWithWebIdentity call needed.
        return DefaultCredentialsProvider.create();
    }

    @Bean
    LettuceClientConfigurationBuilderCustomizer awsElastiCacheLettuceCustomizer(
            AwsCredentialsProvider awsCredentialsProvider) {
        AwsElastiCacheCredentialsProvider credentialsProvider = new AwsElastiCacheCredentialsProvider(
                elastiCacheUserId, replicationGroupId, awsRegion, awsCredentialsProvider, Clock.systemUTC());

        // RedisCredentialsProviderFactory's methods are both `default` (createSentinelCredentials
        // included), so it isn't a true functional interface despite having exactly one
        // "meaningful" method — confirmed live via a real compile failure ("no abstract method
        // found") when a lambda was tried here first. An anonymous class overriding just the
        // standalone method is the correct, minimal fix (Sentinel is out of scope: ElastiCache's
        // managed replication group has no Sentinel process for the app to discover, same
        // reasoning as application.yml's "!cloud" gate on the Sentinel block).
        RedisCredentialsProviderFactory credentialsProviderFactory = new RedisCredentialsProviderFactory() {
            @Override
            public io.lettuce.core.RedisCredentialsProvider createCredentialsProvider(
                    RedisConfiguration redisConfiguration) {
                return credentialsProvider;
            }
        };

        // useSsl(): ElastiCache's replication group now requires TLS (transit_encryption_enabled
        // = true, a hard AWS requirement for IAM auth — see terraform/aws/elasticache-iam-auth.tf
        // and application.yml's "cloud" profile comment on the crash-loop this caused before it
        // was diagnosed). The plain host/port "cloud" profile block has no TLS config at all, so
        // this customizer is also what actually makes the connection speak TLS, not just IAM auth.
        return builder -> builder.useSsl().and().redisCredentialsProviderFactory(credentialsProviderFactory);
    }
}
