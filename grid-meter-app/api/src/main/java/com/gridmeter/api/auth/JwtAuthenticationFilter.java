package com.gridmeter.api.auth;

import io.jsonwebtoken.JwtException;
import io.opentelemetry.api.trace.Span;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.UUID;
import org.slf4j.MDC;
import org.springframework.http.HttpHeaders;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    private static final String CUSTOMER_ID_MDC_KEY = "customerId";

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
            throws ServletException, IOException {
        String header = request.getHeader(HttpHeaders.AUTHORIZATION);
        if (header != null && header.startsWith(BEARER_PREFIX)) {
            try {
                String token = header.substring(BEARER_PREFIX.length());
                String username = jwtService.extractUsername(token);
                UUID customerId = jwtService.extractCustomerId(token);
                AuthenticatedUser principal = new AuthenticatedUser(username, customerId);
                Authentication authToken = new UsernamePasswordAuthenticationToken(
                        principal, null, List.of(new SimpleGrantedAuthority("ROLE_USER")));
                ((UsernamePasswordAuthenticationToken) authToken)
                        .setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authToken);
                // Propagate to Loki (via MDC, cleared below since Tomcat threads are pooled and
                // reused across requests) and to the current Tempo trace span -- see
                // docs/multi-tenancy-scope.md's "logs and traces, not raw Prometheus labels" note.
                MDC.put(CUSTOMER_ID_MDC_KEY, customerId.toString());
                Span.current().setAttribute(CUSTOMER_ID_MDC_KEY, customerId.toString());
            } catch (JwtException ex) {
                SecurityContextHolder.clearContext();
            }
        }
        try {
            chain.doFilter(request, response);
        } finally {
            MDC.remove(CUSTOMER_ID_MDC_KEY);
        }
    }
}
