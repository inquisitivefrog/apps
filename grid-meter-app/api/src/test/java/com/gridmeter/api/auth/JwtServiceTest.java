package com.gridmeter.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Pure unit test — JwtService has no collaborators beyond JwtProperties, no Spring context needed. */
class JwtServiceTest {

    private static final String SECRET = "4H+9b+HAJnUJhWU+mEKE09Onq9J4VzpLkSG3zL4pvAs=";
    private static final UUID CUSTOMER_ID = UUID.randomUUID();

    private JwtService jwtService(long expirationMinutes) {
        JwtProperties properties = new JwtProperties();
        properties.setSecret(SECRET);
        properties.setExpirationMinutes(expirationMinutes);
        return new JwtService(properties);
    }

    @Test
    void generateToken_thenExtractUsername_roundTrips() {
        JwtService jwtService = jwtService(60);

        String token = jwtService.generateToken("demo", CUSTOMER_ID);

        assertThat(jwtService.extractUsername(token)).isEqualTo("demo");
    }

    @Test
    void generateToken_thenExtractCustomerId_roundTrips() {
        JwtService jwtService = jwtService(60);

        String token = jwtService.generateToken("demo", CUSTOMER_ID);

        assertThat(jwtService.extractCustomerId(token)).isEqualTo(CUSTOMER_ID);
    }

    @Test
    void extractUsername_expiredToken_throwsJwtException() throws InterruptedException {
        JwtService jwtService = jwtService(0);
        String token = jwtService.generateToken("demo", CUSTOMER_ID);
        Thread.sleep(50);

        assertThatThrownBy(() -> jwtService.extractUsername(token))
                .isInstanceOf(ExpiredJwtException.class);
    }

    @Test
    void extractUsername_tamperedSignature_throwsJwtException() {
        JwtService jwtService = jwtService(60);
        String token = jwtService.generateToken("demo", CUSTOMER_ID);
        // Flip the second-to-last character, not the last one. An HS256 signature is 32 bytes
        // (256 bits); base64url-without-padding needs 43 characters (43*6=258 bits), so the final
        // character's low 2 bits are unused zero-padding, not real signature bits. Flipping only
        // the very last character can therefore land on a different character that decodes to the
        // exact same signature bytes (e.g. 'A' and 'B' share the same top 4 bits, differing only in
        // that padding), making the "tampered" token accidentally still valid ~1 run in 16 -- this
        // caused a real intermittent CI failure (see status/claude_code_2026-08-24.md). The
        // second-to-last character sits in the final base64 group's first two characters, which are
        // always fully real signature bits with no padding ambiguity, so flipping it is guaranteed
        // to change the decoded signature every time.
        int tamperIndex = token.length() - 2;
        String tampered = token.substring(0, tamperIndex)
                + (token.charAt(tamperIndex) == 'A' ? 'B' : 'A')
                + token.substring(tamperIndex + 1);

        assertThatThrownBy(() -> jwtService.extractUsername(tampered)).isInstanceOf(JwtException.class);
    }

    @Test
    void extractUsername_wrongKey_throwsJwtException() {
        JwtService issuer = jwtService(60);
        String token = issuer.generateToken("demo", CUSTOMER_ID);
        JwtProperties differentKeyProperties = new JwtProperties();
        differentKeyProperties.setSecret("NJWZODDaaCD85U8l39HV8KANMPxjaPQ2jgn7BwHfnwk=");
        differentKeyProperties.setExpirationMinutes(60);
        JwtService verifier = new JwtService(differentKeyProperties);

        assertThatThrownBy(() -> verifier.extractUsername(token)).isInstanceOf(JwtException.class);
    }
}
