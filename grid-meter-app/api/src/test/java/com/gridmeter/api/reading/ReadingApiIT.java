package com.gridmeter.api.reading;

import io.restassured.RestAssured;
import java.net.URI;

/**
 * Black-box tier — see {@link com.gridmeter.api.meter.MeterApiIT}'s Javadoc for the pattern this
 * follows, including the port-8080-default root cause of the "Connection reset" this tier hit.
 * Runs via Failsafe ({@code mvn verify}) against an already-deployed stack.
 */
class ReadingApiIT extends ReadingApiTestBase {

    @Override
    protected void configureRestAssured() {
        String baseUrl = System.getenv().getOrDefault("API_BASE_URL", "http://localhost/api/v1");
        RestAssured.baseURI = baseUrl;
        RestAssured.basePath = "";
        URI uri = URI.create(baseUrl);
        RestAssured.port = uri.getPort() != -1 ? uri.getPort() : ("https".equals(uri.getScheme()) ? 443 : 80);
    }
}
