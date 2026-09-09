package com.gridmeter.api.meter;

import static io.restassured.RestAssured.given;
import static org.awaitility.Awaitility.await;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.notNullValue;
import static org.hamcrest.Matchers.startsWith;

import com.gridmeter.api.auth.dto.LoginRequest;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import java.time.Duration;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Black-box HTTP contract tests for {@code /api/v1/meters}, shared between {@link
 * MeterApiComponentTest} (embedded server, runs via {@code mvn test} on every push) and {@link
 * MeterApiIT} (runs via {@code mvn verify} against a real deployed stack — see
 * docs/testing-strategy.md). Concrete subclasses are responsible only for pointing {@code
 * RestAssured.baseURI}/{@code basePath} at wherever the server actually is; the assertions
 * themselves live here so both tiers exercise the identical contract.
 */
abstract class MeterApiTestBase {

    private String token;

    /**
     * Concrete subclasses point RestAssured at wherever the server actually is (an embedded
     * Testcontainers-backed instance, or a real deployed stack) before every test. Called from
     * {@link #authenticate()} rather than relying on JUnit's superclass/subclass
     * {@code @BeforeEach} ordering, which runs base-class methods first — the opposite of what's
     * needed here, since the login call below depends on the base URI already being set.
     */
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

    private String createMeter(String serialNumber) {
        return authenticated()
                .body("""
                        {"serialNumber":"%s","location":"Test Location","status":"ACTIVE","installedAt":"2026-01-15T00:00:00Z"}
                        """.formatted(serialNumber))
                .when()
                .post("/meters")
                .then()
                .statusCode(201)
                .extract().path("id");
    }

    @Test
    void create_returns201WithLocationHeaderAndBody() {
        String serialNumber = "MTR-" + UUID.randomUUID();

        authenticated()
                .body("""
                        {"serialNumber":"%s","location":"123 Main St","status":"ACTIVE","installedAt":"2026-01-15T00:00:00Z"}
                        """.formatted(serialNumber))
                .when()
                .post("/meters")
                .then()
                .statusCode(201)
                .header("Location", startsWith("/api/v1/meters/"))
                .body("id", notNullValue())
                .body("serialNumber", equalTo(serialNumber))
                .body("location", equalTo("123 Main St"))
                .body("status", equalTo("ACTIVE"));
    }

    @Test
    void create_missingRequiredField_returns400WithValidationDetails() {
        authenticated()
                .body("""
                        {"location":"123 Main St","status":"ACTIVE","installedAt":"2026-01-15T00:00:00Z"}
                        """)
                .when()
                .post("/meters")
                .then()
                .statusCode(400)
                .body("error", equalTo("Bad Request"))
                .body("details", hasItem(containsString("serialNumber")));
    }

    @Test
    void getById_returnsCreatedMeter() {
        String serialNumber = "MTR-" + UUID.randomUUID();
        String id = createMeter(serialNumber);

        authenticated()
                .when()
                .get("/meters/{id}", id)
                .then()
                .statusCode(200)
                .body("id", equalTo(id))
                .body("serialNumber", equalTo(serialNumber));
    }

    @Test
    void getById_unknownId_returns404() {
        authenticated()
                .when()
                .get("/meters/{id}", UUID.randomUUID())
                .then()
                .statusCode(404)
                .body("status", equalTo(404));
    }

    @Test
    void search_clampsRequestedSizeToServerEnforcedMax() {
        authenticated()
                .queryParam("size", 500)
                .when()
                .get("/meters")
                .then()
                .statusCode(200)
                .body("size", equalTo(100))
                .body("content", notNullValue());
    }

    @Test
    void update_changesFieldsAndReturns200() {
        String serialNumber = "MTR-" + UUID.randomUUID();
        String id = createMeter(serialNumber);

        authenticated()
                .body("""
                        {"serialNumber":"%s","location":"New Location","status":"MAINTENANCE","installedAt":"2026-01-15T00:00:00Z"}
                        """.formatted(serialNumber))
                .when()
                .put("/meters/{id}", id)
                .then()
                .statusCode(200)
                .body("location", equalTo("New Location"))
                .body("status", equalTo("MAINTENANCE"));
    }

    @Test
    void update_unknownId_returns404() {
        authenticated()
                .body("""
                        {"serialNumber":"MTR-%s","location":"Nowhere","status":"ACTIVE","installedAt":"2026-01-15T00:00:00Z"}
                        """.formatted(UUID.randomUUID()))
                .when()
                .put("/meters/{id}", UUID.randomUUID())
                .then()
                .statusCode(404);
    }

    @Test
    void delete_returns204ThenGetReturns404() {
        String serialNumber = "MTR-" + UUID.randomUUID();
        String id = createMeter(serialNumber);

        authenticated().when().delete("/meters/{id}", id).then().statusCode(204);

        authenticated().when().get("/meters/{id}", id).then().statusCode(404);
    }

    // Found 2026-09-08 re-verifying docs/k8s-kafka-ha-scope.md's kill test (cleaning up test data
    // hit this by accident): the FK constraint on readings.meter_id rejects this delete with a
    // DataIntegrityViolationException, a DataAccessException subtype -- previously caught by
    // GlobalExceptionHandler's broad "database unavailable" handler and misreported as a 503
    // outage instead of the ordinary client conflict it actually is. See
    // GlobalExceptionHandler.handleDataIntegrityViolation.
    @Test
    void delete_meterWithExistingReadings_returns409NotServiceUnavailable() {
        String serialNumber = "MTR-" + UUID.randomUUID();
        String id = createMeter(serialNumber);

        String readingId = authenticated()
                .header("Idempotency-Key", UUID.randomUUID().toString())
                .body("""
                        {"meterId":"%s","readingTimestamp":"2026-01-15T00:00:00Z","value":5.000}
                        """.formatted(id))
                .when()
                .post("/readings")
                .then()
                .statusCode(201)
                .extract().path("id");

        await().atMost(Duration.ofSeconds(10))
                .pollInterval(Duration.ofMillis(200))
                .untilAsserted(() ->
                        authenticated().when().get("/readings/{id}", readingId).then().statusCode(200));

        authenticated()
                .when()
                .delete("/meters/{id}", id)
                .then()
                .statusCode(409)
                .body("error", equalTo("Conflict"));

        authenticated().when().delete("/readings/{id}", readingId).then().statusCode(204);
        authenticated().when().delete("/meters/{id}", id).then().statusCode(204);
    }
}
