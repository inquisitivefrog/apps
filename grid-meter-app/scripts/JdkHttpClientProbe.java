import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

/**
 * Sends a request via the JDK's built-in java.net.http.HttpClient — a second, independent HTTP
 * client implementation (distinct from both curl and Apache HttpClient) used to help isolate
 * whether a connection issue is specific to one particular client library. Written alongside
 * RawHttpProbe.java while diagnosing a REST Assured (Apache HttpClient 4.5.13) + Docker Desktop
 * for Mac "Connection reset" issue where curl, a raw socket, and this JDK client all succeeded
 * against the same endpoint that Apache HttpClient failed on.
 *
 * Usage: java JdkHttpClientProbe.java <url> [POST-json-body]
 */
public class JdkHttpClientProbe {
    public static void main(String[] args) throws Exception {
        String url = args[0];
        String body = args.length > 1 ? args[1] : null;

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest.Builder builder = HttpRequest.newBuilder().uri(URI.create(url));
        if (body != null) {
            builder.header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(body));
        } else {
            builder.GET();
        }

        HttpResponse<String> response = client.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        System.out.println("status: " + response.statusCode());
        System.out.println("body: " + response.body());
    }
}
