package com.gridmeter.api.common;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import io.github.resilience4j.circuitbreaker.CircuitBreaker;
import io.github.resilience4j.circuitbreaker.CircuitBreakerConfig;
import org.apache.kafka.common.errors.TimeoutException;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.KafkaException;

// Pure unit tests, no Spring MVC context -- calls each @ExceptionHandler method directly, the same
// way ReadingServiceTest builds a plain CircuitBreaker.of(...) rather than a full Spring context.
// Real, HTTP-level confirmation that the two handlers actually dispatch correctly under Spring's
// own exception-resolution machinery (not just "these two methods behave differently in
// isolation") comes from load-tests/kafka-circuitbreaker-loadtest.sh's live re-run -- see
// docs/resilience-scope.md's "Circuit breaker: load-tested under sustained concurrent Kafka
// failure" for that real-outage verification of handleKafkaSendFailure(), and the existing
// ReadingIngestCircuitBreakerLatencyComponentTest for handleCircuitBreakerOpen()'s own real-HTTP
// confirmation.
class GlobalExceptionHandlerTest {

    private final GlobalExceptionHandler handler = new GlobalExceptionHandler();

    // Found 2026-09-11 load-testing kafka-publish under sustained concurrent failure
    // (docs/resilience-scope.md): KafkaTemplate.doSend() wraps a synchronous send() failure as
    // exactly this shape -- org.springframework.kafka.KafkaException("Send failed", cause), root
    // cause org.apache.kafka.common.errors.TimeoutException -- confirmed live against a real
    // outage, not assumed from Kafka's general documentation.
    @Test
    void handleKafkaSendFailure_returns503WithApiError() {
        KafkaException ex = new KafkaException("Send failed",
                new TimeoutException("Topic readings not present in metadata after 60000 ms."));

        ResponseEntity<ApiError> response = handler.handleKafkaSendFailure(ex);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().status()).isEqualTo(503);
        assertThat(response.getBody().error()).isEqualTo("Service Unavailable");
        assertThat(response.getBody().message()).contains("kafka-publish");
    }

    // Confirms the two Kafka-related handlers stay genuinely independent: a CallNotPermittedException
    // (the breaker was already OPEN, the call was never attempted) and a KafkaException (the call
    // WAS permitted but then failed) are unrelated exception hierarchies, so Spring's nearest-match
    // dispatch can never confuse one for the other -- the same "never fire for the same call"
    // property the new handler's own comment states, verified structurally here rather than only
    // asserted in prose.
    @Test
    void kafkaExceptionAndCallNotPermittedException_areUnrelatedHierarchies() {
        assertThat(KafkaException.class.isAssignableFrom(CallNotPermittedException.class)).isFalse();
        assertThat(CallNotPermittedException.class.isAssignableFrom(KafkaException.class)).isFalse();
    }

    @Test
    void handleCircuitBreakerOpen_stillReturns503_independentlyOfTheNewHandler() {
        CircuitBreakerConfig config = CircuitBreakerConfig.custom().build();
        CircuitBreaker breaker = CircuitBreaker.of("kafka-publish", config);
        CallNotPermittedException ex = CallNotPermittedException.createCallNotPermittedException(breaker);

        ResponseEntity<ApiError> response = handler.handleCircuitBreakerOpen(ex);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.SERVICE_UNAVAILABLE);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().message()).contains("kafka-publish");
    }
}
