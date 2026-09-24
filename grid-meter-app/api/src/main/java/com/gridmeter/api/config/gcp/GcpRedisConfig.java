package com.gridmeter.api.config.gcp;

import java.io.File;
import java.time.Clock;
import java.util.Collections;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.data.redis.autoconfigure.LettuceClientConfigurationBuilderCustomizer;
import org.springframework.boot.data.redis.autoconfigure.LettuceClientOptionsBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.data.redis.connection.RedisConfiguration;
import org.springframework.data.redis.connection.lettuce.RedisCredentialsProviderFactory;

import com.google.cloud.iam.credentials.v1.GenerateAccessTokenResponse;
import com.google.cloud.iam.credentials.v1.IamCredentialsClient;
import com.google.protobuf.Duration;

import io.lettuce.core.SslOptions;

/**
 * Wires Memorystore for Valkey IAM auth into the auto-configured LettuceConnectionFactory, the
 * same {@link LettuceClientConfigurationBuilderCustomizer} extension point AWS's
 * {@code AwsRedisConfig} uses.
 * <p>
 * Gated to "cloud-gcp" specifically, not the shared "cloud" profile every cloud deployment
 * activates (see application.yml's cloud profile block): k8s/api-gcp.yaml activates both
 * ("cloud,cloud-gcp") so this bean tree loads only there.
 */
@Configuration
@Profile("cloud-gcp")
public class GcpRedisConfig {

    // GCP's default maximum lifetime for generateAccessToken without extended-lifetime org
    // policy setup - matches GcpMemorystoreCredentialsProvider's own cache-duration comment.
    private static final Duration TOKEN_LIFETIME = Duration.newBuilder().setSeconds(3600).build();
    private static final List<String> CLOUD_PLATFORM_SCOPE =
            Collections.singletonList("https://www.googleapis.com/auth/cloud-platform");

    @Value("${GRID_METER_GCP_SERVICE_ACCOUNT_EMAIL}")
    private String serviceAccountEmail;

    @Value("${GRID_METER_GCP_MEMORYSTORE_CA_PATH}")
    private String memorystoreCaPath;

    @Bean(destroyMethod = "close")
    IamCredentialsClient iamCredentialsClient() throws Exception {
        // Authenticates via Application Default Credentials - under GKE Workload Identity, that's
        // the pod's own bound service account (terraform/gcp/gke.tf's
        // google_service_account_iam_member.app_workload_identity), no separate key file needed.
        return IamCredentialsClient.create();
    }

    @Bean
    LettuceClientConfigurationBuilderCustomizer gcpMemorystoreLettuceCustomizer(
            IamCredentialsClient iamCredentialsClient) {
        // "projects/-/serviceAccounts/<email>" - the exact accountName shape Google's own
        // reference sample uses, a self-impersonation call: the target account is the same one
        // this pod's ambient Workload Identity credentials already let it act as (requires the
        // separate roles/iam.serviceAccountTokenCreator-on-itself grant, terraform/gcp/gke.tf's
        // google_service_account_iam_member.app_token_creator).
        String accountName = "projects/-/serviceAccounts/" + serviceAccountEmail;

        GcpMemorystoreCredentialsProvider credentialsProvider = new GcpMemorystoreCredentialsProvider(
                () -> {
                    GenerateAccessTokenResponse response = iamCredentialsClient.generateAccessToken(
                            accountName, Collections.emptyList(), CLOUD_PLATFORM_SCOPE, TOKEN_LIFETIME);
                    return response.getAccessToken();
                },
                Clock.systemUTC());

        // RedisCredentialsProviderFactory's methods are both `default`, so it isn't a true
        // functional interface - same real compile-time finding AWS's AwsRedisConfig already made
        // ("no abstract method found"). An anonymous class overriding just the standalone method
        // is the correct, minimal fix; Sentinel is out of scope here for the same reason as AWS
        // (Memorystore has no Sentinel process to discover).
        RedisCredentialsProviderFactory credentialsProviderFactory = new RedisCredentialsProviderFactory() {
            @Override
            public io.lettuce.core.RedisCredentialsProvider createCredentialsProvider(
                    RedisConfiguration redisConfiguration) {
                return credentialsProvider;
            }
        };

        // useSsl(): Memorystore's IAM_AUTH mode requires transit encryption
        // (transit_encryption_mode = SERVER_AUTHENTICATION, terraform/gcp/memorystore.tf) - the
        // plain host/port "cloud" profile block has no TLS config at all, same gap AWS's
        // AwsRedisConfig fixes for ElastiCache. The custom trust manager for Memorystore's private
        // per-instance CA is wired separately below via LettuceClientOptionsBuilderCustomizer,
        // not here - useSsl() only carries the simple on/off flag, not a Lettuce-native
        // ClientOptions/SslOptions trust manager (confirmed via javap: LettuceSslClientConfiguration
        // Builder has no trust-manager method at all).
        return builder -> builder.useSsl().and().redisCredentialsProviderFactory(credentialsProviderFactory);
    }

    @Bean
    LettuceClientOptionsBuilderCustomizer gcpMemorystoreClientOptionsCustomizer() {
        // Found live (2026-09-24): Memorystore's TLS cert is signed by a private per-instance
        // Google-managed CA (server_ca_mode = GOOGLE_MANAGED_PER_INSTANCE_CA) the JDK's default
        // trust store has no reason to trust - useSsl() alone produced a real
        // SSLHandshakeException ("PKIX path building failed") even though raw TCP reachability to
        // Memorystore was independently confirmed fine. This is the dedicated Spring Boot hook for
        // Lettuce-native ClientOptions (as opposed to LettuceClientConfigurationBuilderCustomizer's
        // simpler on/off flags above) - matches Google's own official Java/Lettuce reference
        // sample's SslOptions.builder().jdkSslProvider().trustManager(new File(caFileName))
        // exactly. The CA file itself is mounted from a ConfigMap generated at deploy time
        // (k8s/deploy-gcp.sh, from terraform output memorystore_server_ca_certificates) - a
        // deploy-time fact that would drift the moment Memorystore is ever recreated, same
        // reasoning as this app's other generated-at-deploy-time config.
        SslOptions sslOptions = SslOptions.builder()
                .jdkSslProvider()
                .trustManager(new File(memorystoreCaPath))
                .build();
        return builder -> builder.sslOptions(sslOptions);
    }
}
