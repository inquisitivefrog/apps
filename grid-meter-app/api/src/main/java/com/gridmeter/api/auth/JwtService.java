package com.gridmeter.api.auth;

import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.UUID;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

@Service
public class JwtService {

    private final SecretKey key;
    private final Duration expiration;

    public JwtService(JwtProperties properties) {
        this.key = Keys.hmacShaKeyFor(Decoders.BASE64.decode(properties.getSecret()));
        this.expiration = Duration.ofMinutes(properties.getExpirationMinutes());
    }

    // customerId travels as a claim (not looked up per-request) precisely so downstream requests
    // don't need a DB round-trip to resolve which customer they belong to -- see
    // docs/multi-tenancy-scope.md.
    public String generateToken(String username, UUID customerId) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(username)
                .claim("customerId", customerId.toString())
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(expiration)))
                .signWith(key, Jwts.SIG.HS256)
                .compact();
    }

    /** Throws io.jsonwebtoken.JwtException (or a subtype) on tampered signature, expiry, or malformed token. */
    public String extractUsername(String token) {
        return Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload().getSubject();
    }

    /** Throws io.jsonwebtoken.JwtException (or a subtype) on tampered signature, expiry, or malformed token. */
    public UUID extractCustomerId(String token) {
        String raw = Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload().get("customerId", String.class);
        return UUID.fromString(raw);
    }

    public long getExpirationSeconds() {
        return expiration.toSeconds();
    }
}
