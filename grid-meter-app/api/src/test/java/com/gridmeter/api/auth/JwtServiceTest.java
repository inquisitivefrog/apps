package com.gridmeter.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.JwtException;
import org.junit.jupiter.api.Test;

/** Pure unit test — JwtService has no collaborators beyond JwtProperties, no Spring context needed. */
class JwtServiceTest {

    private static final String SECRET = "4H+9b+HAJnUJhWU+mEKE09Onq9J4VzpLkSG3zL4pvAs=";

    private JwtService jwtService(long expirationMinutes) {
        JwtProperties properties = new JwtProperties();
        properties.setSecret(SECRET);
        properties.setExpirationMinutes(expirationMinutes);
        return new JwtService(properties);
    }

    @Test
    void generateToken_thenExtractUsername_roundTrips() {
        JwtService jwtService = jwtService(60);

        String token = jwtService.generateToken("demo");

        assertThat(jwtService.extractUsername(token)).isEqualTo("demo");
    }

    @Test
    void extractUsername_expiredToken_throwsJwtException() throws InterruptedException {
        JwtService jwtService = jwtService(0);
        String token = jwtService.generateToken("demo");
        Thread.sleep(50);

        assertThatThrownBy(() -> jwtService.extractUsername(token))
                .isInstanceOf(ExpiredJwtException.class);
    }

    @Test
    void extractUsername_tamperedSignature_throwsJwtException() {
        JwtService jwtService = jwtService(60);
        String token = jwtService.generateToken("demo");
        String tampered = token.substring(0, token.length() - 1)
                + (token.charAt(token.length() - 1) == 'A' ? 'B' : 'A');

        assertThatThrownBy(() -> jwtService.extractUsername(tampered)).isInstanceOf(JwtException.class);
    }

    @Test
    void extractUsername_wrongKey_throwsJwtException() {
        JwtService issuer = jwtService(60);
        String token = issuer.generateToken("demo");
        JwtProperties differentKeyProperties = new JwtProperties();
        differentKeyProperties.setSecret("NJWZODDaaCD85U8l39HV8KANMPxjaPQ2jgn7BwHfnwk=");
        differentKeyProperties.setExpirationMinutes(60);
        JwtService verifier = new JwtService(differentKeyProperties);

        assertThatThrownBy(() -> verifier.extractUsername(token)).isInstanceOf(JwtException.class);
    }
}
