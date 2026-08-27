package com.gridmeter.api.auth;

import com.gridmeter.api.auth.dto.LoginRequest;
import com.gridmeter.api.auth.dto.LoginResponse;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final UserRepository userRepository;

    public AuthService(
            AuthenticationManager authenticationManager, JwtService jwtService, UserRepository userRepository) {
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
        this.userRepository = userRepository;
    }

    // DaoAuthenticationProvider deliberately maps both "unknown username" and "wrong
    // password" to the same BadCredentialsException, avoiding username enumeration.
    public LoginResponse login(LoginRequest request) {
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.username(), request.password()));
        // One DB lookup here, at login time, so every later request can read customerId straight
        // off the JWT claim instead of repeating this lookup per-request (docs/multi-tenancy-scope.md).
        User user = userRepository.findByUsername(auth.getName())
                .orElseThrow(() -> new IllegalStateException(
                        "Authenticated user vanished between auth and lookup: " + auth.getName()));
        String token = jwtService.generateToken(auth.getName(), user.getCustomerId());
        return new LoginResponse(token, "Bearer", jwtService.getExpirationSeconds());
    }
}
