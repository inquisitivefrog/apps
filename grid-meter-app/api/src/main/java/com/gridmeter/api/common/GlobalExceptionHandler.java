package com.gridmeter.api.common;

import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import java.util.List;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.KafkaException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.transaction.TransactionException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingRequestHeaderException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    // A real, serious bug found live-testing the circuit breaker work against a genuine, sustained
    // full Postgres/Patroni outage (2026-09-04) -- not a circuit-breaker-specific issue, reproduced
    // on a plain, unmodified GET /api/v1/meters with no breaker or @Retryable involved. Without
    // this handler, an uncaught CannotCreateTransactionException (thrown when HikariCP can't even
    // open a connection) reaches Spring MVC's DispatcherServlet with no matching resolver, which
    // falls through to org.springframework.web.util.DisconnectedClientHelper -- a heuristic meant
    // to quietly suppress logging for a genuinely disconnected HTTP client (broken pipe/connection
    // reset), not for a failed backend dependency. That helper explicitly excludes
    // org.springframework.dao.DataAccessException from the check ("Ignore onward connection issues
    // to other servers" -- Spring's own authors clearly intended to guard against exactly this
    // category of misdiagnosis), but org.springframework.transaction.TransactionException (the
    // family CannotCreateTransactionException actually belongs to) is a DIFFERENT exception
    // hierarchy and isn't in that exclusion list -- a real, narrow gap in Spring Framework itself
    // (spring-web 7.0.8), not something this app can patch. The result without an explicit handler
    // here: the request silently returns "200 OK, Content-Length: 0" -- a fabricated success on a
    // request that never actually completed, confirmed via DEBUG-level tracing showing "Looks like
    // the client has gone away: CannotCreateTransactionException..." logged immediately before
    // "Completed 200 OK", even though the real HTTP client (curl, with a 15-30s timeout) was still
    // connected and waiting the whole time. Explicit handling here means ExceptionHandlerException
    // Resolver claims the exception before DispatcherServlet ever reaches that ambiguous fallback
    // path. Scoped to DataAccessException + TransactionException specifically (the two hierarchies
    // covering "the database/transaction layer itself failed," not app-level business logic
    // exceptions, which use their own more specific types elsewhere in this class) -- 503, not 500,
    // since this is a downstream dependency being unavailable, not a bug in this app's own code,
    // matching the same semantic the circuit breaker below already uses for the identical
    // condition once it's had enough failures to actually open.
    @ExceptionHandler({DataAccessException.class, TransactionException.class})
    public ResponseEntity<ApiError> handleDatabaseUnavailable(Exception ex) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(ApiError.of(HttpStatus.SERVICE_UNAVAILABLE.value(), "Service Unavailable",
                        "The database is currently unavailable; try again shortly"));
    }

    // Found 2026-09-08 re-verifying docs/k8s-kafka-ha-scope.md: deleting a meter that still has
    // readings throws DataIntegrityViolationException (the FK constraint on readings.meter_id,
    // V2__create_readings_table.sql, rejecting the delete) -- a subtype of DataAccessException
    // above, so without this more-specific handler it was silently caught by
    // handleDatabaseUnavailable and reported as "the database is unavailable" (503) instead of
    // what it actually is: an ordinary, expected client conflict (a caller trying to delete a
    // meter with dependent history still attached). This is the exact shape
    // docs/resilience-scope.md's own standing lesson warns about, one level down from where it
    // was first written -- the *broad* handler above needed a more-specific carve-out, not the
    // other way around. Spring dispatches @ExceptionHandler methods by nearest-match in the
    // exception hierarchy regardless of declaration order, so this method being declared after
    // the DataAccessException handler above doesn't affect which one wins for this exception type.
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiError> handleDataIntegrityViolation(DataIntegrityViolationException ex) {
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(ApiError.of(HttpStatus.CONFLICT.value(), "Conflict",
                        "This resource cannot be deleted because other records still reference it"));
    }

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

    // Found 2026-09-11 load-testing the kafka-publish breaker under sustained concurrent failure
    // (docs/resilience-scope.md's "Circuit breaker: load-tested under sustained concurrent Kafka
    // failure"): a call that passes kafkaPublishBreaker.tryAcquirePermission() (the breaker is
    // CLOSED or HALF_OPEN, not yet OPEN) can still hit a genuine Kafka-client-level failure --
    // confirmed live via a real outage: KafkaTemplate.doSend() wraps a synchronous send() failure
    // as org.springframework.kafka.KafkaException("Send failed", cause), root cause
    // org.apache.kafka.common.errors.TimeoutException ("Topic readings not present in metadata
    // after <max.block.ms> ms") once the declared max.block.ms budget is exhausted. Distinct from
    // CallNotPermittedException above and never fires for the same call: that one means the
    // breaker was already OPEN and refused to even attempt the call; this one means the call WAS
    // permitted, ReadingService.ingest()'s own synchronous try/catch already recorded it as a
    // breaker failure (onError()) before rethrowing, and without this handler it fell through to
    // Spring's own default error handling as a bare, inconsistent 500 -- the same *shape* of gap
    // (an uncaught exception reaching an ambiguous Spring default instead of an explicit
    // classification) as the Postgres DisconnectedClientHelper finding above, just a different
    // hierarchy. 503, matching every other "a dependency is failing" response in this class.
    @ExceptionHandler(KafkaException.class)
    public ResponseEntity<ApiError> handleKafkaSendFailure(KafkaException ex) {
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(ApiError.of(HttpStatus.SERVICE_UNAVAILABLE.value(), "Service Unavailable",
                        "A dependency (kafka-publish) is currently failing; try again shortly"));
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
