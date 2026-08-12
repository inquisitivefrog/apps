package com.gridmeter.api.auth;

import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;

/**
 * Hand-builds a fixed-shape JSON error body instead of autowiring an ObjectMapper.
 * These handlers run inside the security filter chain, before GlobalExceptionHandler's
 * @RestControllerAdvice ever gets a chance to run — and Spring Boot 4.1 carries two
 * Jackson generations side by side (com.fasterxml.jackson 2.x and tools.jackson 3.x),
 * so guessing which ObjectMapper bean to inject here isn't worth the risk for 5 known,
 * fully-controlled fields.
 */
final class SecurityResponseWriter {

    private SecurityResponseWriter() {
    }

    static void writeApiError(HttpServletResponse response, HttpStatus status, String error, String message)
            throws IOException {
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        String body = """
                {"timestamp":"%s","status":%d,"error":"%s","message":"%s","details":[]}"""
                .formatted(Instant.now(), status.value(), escape(error), escape(message));
        response.getWriter().write(body);
    }

    private static String escape(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
