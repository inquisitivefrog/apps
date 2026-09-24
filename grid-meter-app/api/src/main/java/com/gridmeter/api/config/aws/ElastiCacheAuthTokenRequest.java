package com.gridmeter.api.config.aws;

import java.net.URI;
import java.time.Duration;

import software.amazon.awssdk.auth.credentials.AwsCredentials;
import software.amazon.awssdk.http.SdkHttpFullRequest;
import software.amazon.awssdk.http.SdkHttpMethod;
import software.amazon.awssdk.http.auth.aws.signer.AwsV4HttpSigner;
import software.amazon.awssdk.http.auth.spi.signer.SignedRequest;

/**
 * Builds the SigV4-signed, never-actually-sent request URI that ElastiCache accepts as a Redis
 * AUTH password for IAM-auth users (terraform/aws/elasticache-iam-auth.tf's aws_elasticache_user).
 * Mirrors AWS's own reference implementation
 * (github.com/aws-samples/elasticache-iam-auth-demo-app's IAMAuthTokenRequest, confirmed
 * 2026-09-23 against its current source — it moved off the older auth-module Aws4Signer to
 * AwsV4HttpSigner, so this follows that, not the deprecated one) rather than a hand-derived
 * construction, since getting SigV4 canonicalization subtly wrong fails silently as an auth
 * rejection, not a compile error.
 */
class ElastiCacheAuthTokenRequest {

    private static final SdkHttpMethod REQUEST_METHOD = SdkHttpMethod.GET;
    private static final String REQUEST_PROTOCOL = "http://";
    private static final String PARAM_ACTION = "Action";
    private static final String PARAM_USER = "User";
    private static final String ACTION_NAME = "connect";
    private static final String SERVICE_NAME = "elasticache";
    private static final Duration TOKEN_EXPIRY = Duration.ofSeconds(900);

    private final String userId;
    private final String replicationGroupId;
    private final String region;

    ElastiCacheAuthTokenRequest(String userId, String replicationGroupId, String region) {
        this.userId = userId;
        this.replicationGroupId = replicationGroupId;
        this.region = region;
    }

    String toSignedRequestUri(AwsCredentials credentials) {
        SdkHttpFullRequest request = SdkHttpFullRequest.builder()
                .method(REQUEST_METHOD)
                .uri(URI.create("%s%s/".formatted(REQUEST_PROTOCOL, replicationGroupId)))
                .appendRawQueryParameter(PARAM_ACTION, ACTION_NAME)
                .appendRawQueryParameter(PARAM_USER, userId)
                .build();

        AwsV4HttpSigner signer = AwsV4HttpSigner.create();
        SignedRequest signedRequest = signer.sign(r -> r.identity(credentials)
                .request(request)
                .putProperty(AwsV4HttpSigner.SERVICE_SIGNING_NAME, SERVICE_NAME)
                .putProperty(AwsV4HttpSigner.REGION_NAME, region)
                .putProperty(AwsV4HttpSigner.AUTH_LOCATION, AwsV4HttpSigner.AuthLocation.QUERY_STRING)
                .putProperty(AwsV4HttpSigner.EXPIRATION_DURATION, TOKEN_EXPIRY)
                .build());

        // The signed URI is the token itself, never actually sent as an HTTP request — Redis's
        // AUTH command takes it as a password. Strip the scheme, matching what ElastiCache expects
        // (and what AWS's own reference implementation does).
        return ((SdkHttpFullRequest) signedRequest.request()).getUri().toString().replace(REQUEST_PROTOCOL, "");
    }
}
