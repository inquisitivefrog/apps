package com.gridmeter.api.config.azure;

import java.nio.charset.StandardCharsets;
import java.time.OffsetDateTime;
import java.util.Base64;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.azure.core.credential.AccessToken;
import com.azure.core.credential.TokenRequestContext;
import com.azure.identity.DefaultAzureCredential;

import io.lettuce.authx.TokenBasedRedisCredentialsProvider;
import io.lettuce.core.RedisCredentials;
import reactor.core.publisher.Mono;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

/**
 * There is no custom credentials-caching class in this package to test the way AWS's/GCP's own
 * *CredentialsProviderTest classes do - the actual token fetch/cache/renewal logic lives entirely
 * in Lettuce's own already-tested io.lettuce.authx.TokenBasedRedisCredentialsProvider and Redis's
 * own redis-authx-entraid library. What this test verifies instead is the one thing this project
 * actually owns: that AzureRedisConfig's bean-construction wiring correctly threads a
 * DefaultAzureCredential's resolved token through to the RedisCredentials Lettuce ultimately uses,
 * and that the Redis-specific OAuth2 scope is the one actually requested - exercising the real
 * production wiring method with a mocked credential, not a reimplementation of it.
 * <p>
 * Found live (2026-09-24) that redis-authx-entraid's AzureIdentityProvider doesn't treat the
 * access token as an opaque string - it parses it as a real JWT (JWToken -> auth0's JWT.decode())
 * and reads two real claims: "oid" (used as the Redis AUTH *username* - a genuine, previously-
 * unconfirmed fact, not a fixed string like GCP's literal "default") and "exp" (the token's real
 * expiry, read via the JWT's own claim rather than trusting a caller-supplied Duration). A plain
 * non-JWT string here caused every internal renewal attempt to fail identically and retry
 * indefinitely (JWTDecodeException: "expected 3 parts, got 0") - not a hang, an infinite retry
 * loop invisible to a `.block()` caller since credentials never actually resolve. Fixed by
 * constructing a structurally-valid (unsigned, decode() doesn't verify signatures) fake JWT with
 * both required claims, not a bug in AzureRedisConfig itself.
 */
class AzureRedisConfigTest {

    private static final String FAKE_OID = "fake-oid-1234";

    private static String fakeJwt(long expiresAtEpochSeconds) {
        String header = base64Url("{\"alg\":\"none\",\"typ\":\"JWT\"}");
        String payload = base64Url("{\"oid\":\"" + FAKE_OID + "\",\"exp\":" + expiresAtEpochSeconds + "}");
        return header + "." + payload + "." + base64Url("unsigned");
    }

    private static String base64Url(String value) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(value.getBytes(StandardCharsets.UTF_8));
    }

    @Test
    void resolvesCredentialsFromTheProvidedAzureCredentialWithTheRedisScope() throws Exception {
        DefaultAzureCredential credential = mock(DefaultAzureCredential.class);
        String fakeToken = fakeJwt(OffsetDateTime.now().plusHours(1).toEpochSecond());
        when(credential.getToken(any()))
                .thenReturn(Mono.just(new AccessToken(fakeToken, OffsetDateTime.now().plusHours(1))));

        AzureRedisConfig config = new AzureRedisConfig();
        TokenBasedRedisCredentialsProvider provider = config.tokenBasedRedisCredentialsProvider(credential);
        try {
            RedisCredentials credentials = provider.resolveCredentials().block();
            assertThat(credentials.getUsername()).isEqualTo(FAKE_OID);
            assertThat(new String(credentials.getPassword())).isEqualTo(fakeToken);

            ArgumentCaptor<TokenRequestContext> contextCaptor = ArgumentCaptor.forClass(TokenRequestContext.class);
            verify(credential).getToken(contextCaptor.capture());
            assertThat(contextCaptor.getValue().getScopes()).containsExactly("https://redis.azure.com/.default");
        } finally {
            provider.close();
        }
    }
}
