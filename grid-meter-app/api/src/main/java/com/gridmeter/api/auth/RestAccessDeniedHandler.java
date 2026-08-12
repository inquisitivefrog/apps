package com.gridmeter.api.auth;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

/**
 * Effectively unreachable today — there's no role-gated resource beyond the single
 * implicit ROLE_USER every authenticated request carries. Added anyway so the API never
 * silently falls back to Spring Security's default HTML error page; every error response
 * stays JSON-shaped, matching the rest of the contract.
 */
@Component
public class RestAccessDeniedHandler implements AccessDeniedHandler {

    @Override
    public void handle(HttpServletRequest request, HttpServletResponse response, AccessDeniedException ex)
            throws IOException {
        SecurityResponseWriter.writeApiError(
                response, HttpStatus.FORBIDDEN, "Forbidden", "You do not have access to this resource");
    }
}
