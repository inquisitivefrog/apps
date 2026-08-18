package com.gridmeter.api.meter;

import io.restassured.RestAssured;
import java.net.URI;

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
 *
 * <p><b>Root cause of the "Connection reset" that blocked this tier for a session:</b> REST
 * Assured's static {@code RestAssured.port} defaults to 8080, and it silently applies that
 * default to any request whose URL doesn't explicitly carry a port — including a full {@code
 * baseURI} like {@code http://localhost/api/v1}. Every request was actually going to
 * Traefik's <em>dashboard</em> port (8080, see {@code docker-compose.yml}), which resets any
 * connection it doesn't recognize as its own API. Confirmed with a packet capture: curl, a raw
 * socket, the JDK's {@code HttpClient}, and even Apache HttpClient 4.5.13 called directly (REST
 * Assured's own underlying client, both its modern and legacy execution paths) all correctly hit
 * port 80 and succeeded — only requests built by REST Assured's Groovy {@code HTTPBuilder} layer
 * went to 8080. Fixed by deriving {@code RestAssured.port} explicitly from the base URL below,
 * rather than leaving it at REST Assured's default. See {@code scripts/probe-restassured-minimal.sh}
 * and {@code scripts/capture-connection-reset.sh} for the probes that isolated this.
 */
class MeterApiIT extends MeterApiTestBase {

    @Override
    protected void configureRestAssured() {
        String baseUrl = System.getenv().getOrDefault("API_BASE_URL", "http://localhost/api/v1");
        RestAssured.baseURI = baseUrl;
        RestAssured.basePath = "";
        URI uri = URI.create(baseUrl);
        RestAssured.port = uri.getPort() != -1 ? uri.getPort() : ("https".equals(uri.getScheme()) ? 443 : 80);
    }
}
