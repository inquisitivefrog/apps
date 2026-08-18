package com.gridmeter.api.reading;

import io.restassured.RestAssured;
import io.restassured.config.HttpClientConfig;
import io.restassured.config.RestAssuredConfig;

/**
 * Black-box tier — see {@link com.gridmeter.api.meter.MeterApiIT}'s Javadoc for the pattern this
 * follows, including why Expect-Continue is disabled below. Runs via Failsafe ({@code mvn
 * verify}) against an already-deployed stack.
 */
class ReadingApiIT extends ReadingApiTestBase {

    @Override
    protected void configureRestAssured() {
        String baseUrl = System.getenv().getOrDefault("API_BASE_URL", "http://localhost/api/v1");
        RestAssured.baseURI = baseUrl;
        RestAssured.basePath = "";
        RestAssured.config = RestAssuredConfig.config().httpClient(
                HttpClientConfig.httpClientConfig().setParam("http.protocol.expect-continue", false));
    }
}
