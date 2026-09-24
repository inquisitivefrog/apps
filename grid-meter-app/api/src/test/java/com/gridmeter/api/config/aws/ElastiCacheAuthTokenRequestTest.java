package com.gridmeter.api.config.aws;

import org.junit.jupiter.api.Test;

import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentials;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * The SigV4 signing itself is a deterministic, offline operation (no network call — the token is
 * never actually sent, per ElastiCache's IAM-auth design), so this exercises the real
 * AwsV4HttpSigner against fake static credentials rather than mocking anything, catching a
 * canonicalization mistake a mock would hide.
 */
class ElastiCacheAuthTokenRequestTest {

    private static final AwsCredentials FAKE_CREDENTIALS =
            AwsBasicCredentials.create("AKIAFAKEACCESSKEY", "fakeSecretAccessKey1234567890");

    @Test
    void producesATokenShapedForRedisAuth() {
        ElastiCacheAuthTokenRequest request =
                new ElastiCacheAuthTokenRequest("app", "grid-meter-redis", "us-east-1");

        String token = request.toSignedRequestUri(FAKE_CREDENTIALS);

        // Never sent as a real HTTP request -- Redis's AUTH command takes this string as a
        // password -- so it must not carry the "http://" scheme ElastiCache doesn't expect.
        assertThat(token).doesNotStartWith("http://");
        assertThat(token).startsWith("grid-meter-redis/");
        assertThat(token).contains("Action=connect");
        assertThat(token).contains("User=app");
        assertThat(token).contains("X-Amz-Signature=");
        assertThat(token).contains("X-Amz-Algorithm=AWS4-HMAC-SHA256");
    }

    @Test
    void encodesTheGivenUserAndRegionIntoTheSignature() {
        ElastiCacheAuthTokenRequest request =
                new ElastiCacheAuthTokenRequest("other-user", "grid-meter-redis", "eu-west-1");

        String token = request.toSignedRequestUri(FAKE_CREDENTIALS);

        assertThat(token).contains("User=other-user");
        // Credential scope is URL-encoded in the query string (%2F, not a literal "/") --
        // confirmed by running this test for real rather than assumed.
        assertThat(token).contains("%2Feu-west-1%2Felasticache%2Faws4_request");
    }

    @Test
    void differentUsersProduceDifferentSignatures() {
        ElastiCacheAuthTokenRequest appUser =
                new ElastiCacheAuthTokenRequest("app", "grid-meter-redis", "us-east-1");
        ElastiCacheAuthTokenRequest otherUser =
                new ElastiCacheAuthTokenRequest("someone-else", "grid-meter-redis", "us-east-1");

        assertThat(appUser.toSignedRequestUri(FAKE_CREDENTIALS))
                .isNotEqualTo(otherUser.toSignedRequestUri(FAKE_CREDENTIALS));
    }
}
