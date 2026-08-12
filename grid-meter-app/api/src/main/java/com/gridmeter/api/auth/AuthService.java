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

    public AuthService(AuthenticationManager authenticationManager, JwtService jwtService) {
        this.authenticationManager = authenticationManager;
        this.jwtService = jwtService;
    }

    // DaoAuthenticationProvider deliberately maps both "unknown username" and "wrong
    // password" to the same BadCredentialsException, avoiding username enumeration.
    public LoginResponse login(LoginRequest request) {
        Authentication auth = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.username(), request.password()));
        String token = jwtService.generateToken(auth.getName());
        return new LoginResponse(token, "Bearer", jwtService.getExpirationSeconds());
    }
}
