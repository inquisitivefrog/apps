package com.gridmeter.api.auth;

import com.gridmeter.api.auth.dto.LoginRequest;
import com.gridmeter.api.auth.dto.LoginResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final UserRepository userRepository;
    private final ActiveUserTracker activeUserTracker;

    public AuthService(
            AuthenticationManager authenticationManager,
            JwtService jwtService,
            UserRepository userRepository,
            ActiveUserTracker activeUserTracker) {
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.userRepository = userRepository;
        this.activeUserTracker = activeUserTracker;
    }

    // DaoAuthenticationProvider deliberately maps both "unknown username" and "wrong
    // password" to the same BadCredentialsException, avoiding username enumeration.
    //
    // Every attempt is logged as "event=login outcome=success|failure user=<name>" -- a fixed shape
    // the Grafana "Logins" dashboard extracts with a LogQL regexp (recent logins, logins per user,
    // failed attempts per username). Usernames live in logs, not Prometheus labels: one label value
    // per user would mean one time series per user.
    public LoginResponse login(LoginRequest request) {
        Authentication auth;
        try {
            auth = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(request.username(), request.password()));
        } catch (AuthenticationException ex) {
            log.info("event=login outcome=failure user={}", loggable(request.username()));
            throw ex;
        }
        // One DB lookup here, at login time, so every later request can read customerId straight
        // off the JWT claim instead of repeating this lookup per-request (docs/multi-tenancy-scope.md).
        User user = userRepository.findByUsername(auth.getName())
                .orElseThrow(() -> new IllegalStateException(
                        "Authenticated user vanished between auth and lookup: " + auth.getName()));
        String token = jwtService.generateToken(auth.getName(), user.getCustomerId());
        activeUserTracker.recordLogin(auth.getName());
        log.info("event=login outcome=success user={}", loggable(auth.getName()));
        return new LoginResponse(token, "Bearer", jwtService.getExpirationSeconds());
    }

    // A failed attempt's username is whatever the client sent: replace whitespace and control
    // characters so it can't forge a second log line (CR/LF) or break the user= field, and cap the
    // length at the users.username column size so a huge value can't bloat the logs.
    static String loggable(String username) {
        String cleaned = username.replaceAll("[\\s\\p{Cntrl}]", "_");
        return cleaned.length() > 100 ? cleaned.substring(0, 100) + "..." : cleaned;
    }
}
