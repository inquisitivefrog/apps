package com.gridmeter.api.reading;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.startsWith;

import com.gridmeter.api.auth.dto.LoginRequest;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.specification.RequestSpecification;
import java.math.BigDecimal;
import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Black-box HTTP contract tests for {@code /api/v1/readings}, shared between {@link
 * ReadingApiComponentTest} (embedded, {@code mvn test}) and {@link ReadingApiIT} (a real deployed
 * stack, {@code mvn verify}) — see {@link com.gridmeter.api.meter.MeterApiTestBase}'s Javadoc for
 * why the split exists. Readings are ingested asynchronously (POST publishes to Kafka; a consumer
 * writes Postgres + Redis on a different thread — see {@code ReadingEventConsumer}), so read-after-
 * write assertions poll with Awaitility rather than assuming immediate consistency, the same
 * approach {@code ReadingComponentTest} uses at the service layer.
 */
abstract class ReadingApiTestBase {

    private String token;

    protected abstract void configureRestAssured();

    @BeforeEach
    void authenticate() {
        configureRestAssured();
        token = given()
                .contentType(ContentType.JSON)
                .body(new LoginRequest("demo", "GridMeter!Demo2026"))
                .when()
                .post("/auth/login")
                .then()
                .statusCode(200)
                .extract().path("accessToken");
    }

    private RequestSpecification authenticated() {
        return given().header("Authorization", "Bearer " + token).contentType(ContentType.JSON);
    }

    private String createMeter() {
        return authenticated()
                .body("""
                        {"serialNumber":"MTR-%s","location":"Test Location","status":"ACTIVE","installedAt":"2026-01-15T00:00:00Z"}
                        """.formatted(UUID.randomUUID()))
                .when()
                .post("/meters")
                .then()
                .statusCode(201)
                .extract().path("id");
    }

    private String ingestReading(String meterId, String value) {
        return authenticated()
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .body("""
                        {"meterId":"%s","readingTimestamp":"2026-08-11T06:00:00Z","value":%s}
                        """.formatted(meterId, value))
                .when()
                .post("/readings")
                .then()
                .statusCode(201)
                .extract().path("id");
    }

    private void awaitPersisted(String readingId) {
        await().atMost(Duration.ofSeconds(10))
                .pollInterval(Duration.ofMillis(200))
                .untilAsserted(() ->
                        authenticated().when().get("/readings/{id}", readingId).then().statusCode(200));
    }

    @Test
    void ingest_returns201WithLocationHeaderAndBody() {
        String meterId = createMeter();

        authenticated()
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .body("""
                        {"meterId":"%s","readingTimestamp":"2026-08-11T06:00:00Z","value":42.5}
                        """.formatted(meterId))
                .when()
                .post("/readings")
                .then()
                .statusCode(201)
                .header("Location", startsWith("/api/v1/readings/"))
                .body("id", notNullValue())
                .body("meterId", equalTo(meterId));
    }

    @Test
    void ingest_unknownMeterId_returns404() {
        authenticated()
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .body("""
                        {"meterId":"%s","readingTimestamp":"2026-08-11T06:00:00Z","value":42.5}
                        """.formatted(UUID.randomUUID()))
                .when()
                .post("/readings")
                .then()
                .statusCode(404);
    }

    @Test
    void ingest_missingRequiredField_returns400() {
        authenticated()
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .body("""
                        {"readingTimestamp":"2026-08-11T06:00:00Z","value":42.5}
                        """)
                .when()
                .post("/readings")
                .then()
                .statusCode(400)
                .body("error", equalTo("Bad Request"));
    }

    @Test
    void ingest_missingIdempotencyKeyHeader_returns400() {
        String meterId = createMeter();

        authenticated()
                .body("""
                        {"meterId":"%s","readingTimestamp":"2026-08-11T06:00:00Z","value":42.5}
                        """.formatted(meterId))
                .when()
                .post("/readings")
                .then()
                .statusCode(400)
                .body("error", equalTo("Bad Request"));
    }

    // Black-box counterpart to ReadingIdempotencyComponentTest's
    // duplicateKey_sameRequestSentTwice_exactlyOneRowPersisted, per docs/idempotency-scope.md's
    // "API (REST Assured / Bruno)" testing-implications entry: both requests return 201 (a
    // duplicate is normal traffic, not a client error), but a follow-up search shows exactly one
    // row -- the two-layer design's actual, observable guarantee from a client's perspective.
    @Test
    void ingest_sameIdempotencyKeyTwice_bothReturn201ButOnlyOneRowPersists() {
        String meterId = createMeter();
        String idempotencyKey = UUID.randomUUID().toString();
        String body = """
                {"meterId":"%s","readingTimestamp":"2026-08-11T06:00:00Z","value":77.500}
                """.formatted(meterId);

        authenticated()
                .header("Idempotency-Key", idempotencyKey)
                .body(body)
                .when()
                .post("/readings")
                .then()
                .statusCode(201);
        authenticated()
                .header("Idempotency-Key", idempotencyKey)
                .body(body)
                .when()
                .post("/readings")
                .then()
                .statusCode(201);

        // during(): must STAY at exactly 1 across the whole poll window, not just reach it --
        // same reasoning as ReadingIdempotencyComponentTest's identical use of during().
        await().atMost(Duration.ofSeconds(15))
                .pollInterval(Duration.ofMillis(200))
                .during(Duration.ofSeconds(3))
                .untilAsserted(() -> authenticated()
                        .queryParam("meterId", meterId)
                        .when()
                        .get("/readings")
                        .then()
                        .statusCode(200)
                        .body("content.size()", equalTo(1)));
    }

    @Test
    void getById_eventuallyReturnsIngestedReading() {
        String meterId = createMeter();
        String readingId = ingestReading(meterId, "42.500");

        awaitPersisted(readingId);

        Response response = authenticated().when().get("/readings/{id}", readingId);
        response.then().statusCode(200).body("meterId", equalTo(meterId));
        assertThat(new BigDecimal(response.jsonPath().getString("value")))
                .isEqualByComparingTo("42.500");
    }

    @Test
    void getById_unknownId_returns404() {
        authenticated()
                .when()
                .get("/readings/{id}", UUID.randomUUID())
                .then()
                .statusCode(404);
    }

    @Test
    void search_clampsRequestedSizeToServerEnforcedMax() {
        authenticated()
                .queryParam("size", 500)
                .when()
                .get("/readings")
                .then()
                .statusCode(200)
                .body("size", equalTo(100))
                .body("content", notNullValue());
    }

    /**
     * The architectural decision this whole test class exists to enforce at the HTTP level (see
     * docs/testing-strategy.md: "tests should assert the PUT is rejected, not just that it's
     * absent"). There is no {@code @PutMapping} on {@code ReadingController} at all, so Spring MVC
     * itself rejects this with a 405 before any application code runs.
     */
    @Test
    void putReading_isRejectedWith405() {
        String meterId = createMeter();
        String readingId = ingestReading(meterId, "10.000");
        awaitPersisted(readingId);

        authenticated()
                .body("""
                        {"meterId":"%s","readingTimestamp":"2026-08-11T06:00:00Z","value":999.000}
                        """.formatted(meterId))
                .when()
                .put("/readings/{id}", readingId)
                .then()
                .statusCode(405);
    }

    @Test
    void delete_returns204ThenGetReturns404() {
        String meterId = createMeter();
        String readingId = ingestReading(meterId, "5.000");
        awaitPersisted(readingId);

        authenticated().when().delete("/readings/{id}", readingId).then().statusCode(204);

        authenticated().when().get("/readings/{id}", readingId).then().statusCode(404);
    }
}
