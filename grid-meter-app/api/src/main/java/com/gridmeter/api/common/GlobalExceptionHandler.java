package com.gridmeter.api.common;

import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // docs/resilience-scope.md's "Behavior when open": a fast, explicit 503 rather than the
    // request hanging or a bare 500 -- consistent for both ReadingService.ingest()'s breakers
    // (postgres-existence-check, kafka-publish), which this same handler covers regardless of
    // which one tripped, since the caller-facing contract (retry later) is identical either way.
    // Distinct from Traefik's own edge-level 503 shedding (docs/resilience-scope.md's "Outcome"):
    // Traefik's readiness check is deliberately Kafka/Postgres-independent (repointed there after
    // the full aggregate health check incorrectly took down unrelated read traffic during a
    // Kafka-only outage), so it never fires for this specific case -- this is the layer that
    // actually protects the ingest path specifically, not a duplicate of the edge check.
    @ExceptionHandler(CallNotPermittedException.class)
    public ResponseEntity<ApiError> handleCircuitBreakerOpen(CallNotPermittedException ex) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(ApiError.of(HttpStatus.SERVICE_UNAVAILABLE.value(), "Service Unavailable",
                        "A dependency (" + ex.getCausingCircuitBreakerName() + ") is currently failing; try again shortly"));
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(ResourceNotFoundException ex) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(ApiError.of(HttpStatus.NOT_FOUND.value(), "Not Found", ex.getMessage()));
    }

    // Covers POST /api/v1/auth/login's own bad-credentials path — this reaches normal MVC
    // dispatch (unlike the filter-chain-level 401s handled by RestAuthenticationEntryPoint,
    // which run before this @RestControllerAdvice ever gets a chance to run).
    @ExceptionHandler(AuthenticationException.class)
    public ResponseEntity<ApiError> handleAuthenticationFailure(AuthenticationException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(ApiError.of(HttpStatus.UNAUTHORIZED.value(), "Unauthorized", "Invalid username or password"));
    }

    // docs/idempotency-scope.md: POST /readings' required Idempotency-Key header, missing ->
    // 400. Spring rejects a missing @RequestHeader before this @RestControllerAdvice by default
    // too, but with its own error body shape -- this keeps the response consistent with every
    // other 400 this API returns.
    @ExceptionHandler(MissingRequestHeaderException.class)
    public ResponseEntity<ApiError> handleMissingHeader(MissingRequestHeaderException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiError.of(HttpStatus.BAD_REQUEST.value(), "Bad Request",
                        "Missing required header: " + ex.getHeaderName()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        List<String> details = ex.getBindingResult().getFieldErrors().stream()
                .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                .toList();
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiError.of(HttpStatus.BAD_REQUEST.value(), "Bad Request", "Validation failed", details));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ApiError> handleIllegalArgument(IllegalArgumentException ex) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(ApiError.of(HttpStatus.BAD_REQUEST.value(), "Bad Request", ex.getMessage()));
    }
}
