import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import io.restassured.response.Response;

/**
 * Sends a request via REST Assured directly — the actual library under test, not a hand-rolled
 * Apache HttpClient call — but with no surrounding test-suite scaffolding (no Spring, no
 * Awaitility, no shared base class). ApacheHttpClientProbe.java and
 * ApacheHttpClientLegacyProbe.java both succeeded via Apache HttpClient's modern and legacy
 * execution paths respectively, ruling out Apache HttpClient itself; this probe checks whether
 * REST Assured's own Groovy HTTPBuilder layer on top of that same HttpClient is where the
 * "Connection reset" actually originates. See the dated file under status/ for where this
 * investigation stands.
 *
 * Usage: java RestAssuredMinimalProbe.java <url> [POST-json-body]
 */
public class RestAssuredMinimalProbe {
    public static void main(String[] args) throws Exception {
        String url = args[0];
        String body = args.length > 1 && !args[1].isEmpty() ? args[1] : null;

        Response response;
        if (body != null) {
            response = RestAssured.given()
                    .contentType(ContentType.JSON)
                    .body(body)
                    .when()
                    .post(url);
        } else {
            response = RestAssured.given()
                    .when()
                    .get(url);
        }

        System.out.println("status: " + response.getStatusCode());
        System.out.println("body: " + response.getBody().asString());
    }
}
