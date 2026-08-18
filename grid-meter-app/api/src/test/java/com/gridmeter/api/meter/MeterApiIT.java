package com.gridmeter.api.meter;

import io.restassured.RestAssured;
import io.restassured.config.HttpClientConfig;
import io.restassured.config.RestAssuredConfig;

/**
 * Black-box tier: {@link MeterApiTestBase}'s contract tests against a real, already-deployed
 * stack (Traefik + api + Postgres + Kafka + Redis via {@code docker compose up}) rather than an
 * embedded server this class starts itself. No Spring/Testcontainers annotations here at all —
 * deliberately a plain JUnit 5 class, since there's nothing for it to bring up; something else
 * (CI's black-box job, or a developer's local {@code docker compose up}) must already be running.
 * Runs via Failsafe ({@code mvn verify}), not Surefire, so a bare {@code mvn test} never fails
 * here for lack of a deployed stack. Base URL defaults to Traefik on localhost:80, matching the
 * local dev workflow in CLAUDE.md; override with the API_BASE_URL env var (e.g. in CI, where
 * Traefik may not be on the default port).
 */
class MeterApiIT extends MeterApiTestBase {

    @Override
    protected void configureRestAssured() {
        String baseUrl = System.getenv().getOrDefault("API_BASE_URL", "http://localhost/api/v1");
        RestAssured.baseURI = baseUrl;
        RestAssured.basePath = "";
        // Apache HttpClient's default "Expect: 100-continue" on POST/PUT bodies triggers a
        // connection reset from Traefik (not seen against the embedded-server tier, which has no
        // proxy in front of it) — a known interaction, see traefik/traefik#9175.
        RestAssured.config = RestAssuredConfig.config().httpClient(
                HttpClientConfig.httpClientConfig().setParam("http.protocol.expect-continue", false));
    }
}
