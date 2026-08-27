package com.gridmeter.api.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import jakarta.servlet.FilterChain;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.slf4j.MDC;
import org.springframework.security.core.context.SecurityContextHolder;

/**
 * Pure unit test — verifies the customerId propagation this filter is responsible for
 * (docs/multi-tenancy-scope.md), not just that the JWT itself round-trips (see JwtServiceTest).
 */
class JwtAuthenticationFilterTest {

    private final JwtProperties properties = new JwtProperties();
    private final JwtService jwtService;
    private final JwtAuthenticationFilter filter;

    JwtAuthenticationFilterTest() {
        properties.setSecret("4H+9b+HAJnUJhWU+mEKE09Onq9J4VzpLkSG3zL4pvAs=");
        properties.setExpirationMinutes(60);
        jwtService = new JwtService(properties);
        filter = new JwtAuthenticationFilter(jwtService);
    }

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void doFilterInternal_validToken_setsMdcDuringRequestAndClearsItAfter() throws Exception {
        UUID customerId = UUID.randomUUID();
        String token = jwtService.generateToken("demo", customerId);
        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);
        // Assert the MDC value from inside the chain itself -- the request is still "in flight" at
        // that point, which is what a real log statement executing mid-request would observe.
        org.mockito.Mockito.doAnswer(invocation -> {
            assertThat(MDC.get("customerId")).isEqualTo(customerId.toString());
            return null;
        }).when(chain).doFilter(request, response);

        filter.doFilterInternal(request, response, chain);

        verify(chain).doFilter(request, response);
        assertThat(MDC.get("customerId")).isNull();
    }

    @Test
    void doFilterInternal_validToken_setsAuthenticatedUserPrincipalWithCustomerId() throws Exception {
        UUID customerId = UUID.randomUUID();
        String token = jwtService.generateToken("demo", customerId);
        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn("Bearer " + token);

        filter.doFilterInternal(request, response, chain);

        var principal = (AuthenticatedUser) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        assertThat(principal.username()).isEqualTo("demo");
        assertThat(principal.customerId()).isEqualTo(customerId);
    }

    @Test
    void doFilterInternal_noAuthorizationHeader_leavesMdcEmpty() throws Exception {
        HttpServletRequest request = mock(HttpServletRequest.class);
        HttpServletResponse response = mock(HttpServletResponse.class);
        FilterChain chain = mock(FilterChain.class);
        when(request.getHeader("Authorization")).thenReturn(null);

        filter.doFilterInternal(request, response, chain);

        verify(chain).doFilter(request, response);
        assertThat(MDC.get("customerId")).isNull();
    }
}
