import org.apache.http.HttpEntity;
import org.apache.http.client.config.RequestConfig;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;

/**
 * Sends a request via Apache HttpClient 4.5.13 directly — the same library/version REST Assured
 * bundles internally — bypassing REST Assured and Groovy entirely. Written to isolate whether a
 * "Connection reset" seen only through REST Assured against the real Traefik-fronted stack is
 * caused by Apache HttpClient's own connection handling, or by something in REST Assured's/
 * Groovy's layer on top of it, including whether REST Assured's legacy
 * {@code HttpClientConfig.setParam("http.protocol.expect-continue", false)} call actually takes
 * effect against this HttpClient version. See RawHttpProbe.java/JdkHttpClientProbe.java for the
 * other two probes in this same investigation, and the dated file under status/ for where it
 * stands.
 *
 * Set the "probe.chunked" system property to "true" to send the POST body as chunked
 * transfer-encoding (no upfront Content-Length) instead of a fixed-length entity — REST Assured's
 * HTTPBuilder layer is suspected of doing this by default, which Docker Desktop for Mac's port-80
 * forwarding proxy may not handle the same way plain Apache HttpClient usage (fixed-length entity)
 * does.
 *
 * Usage: java -Dprobe.chunked=true ApacheHttpClientProbe.java <url> <expect-continue:true|false> [POST-json-body]
 */
public class ApacheHttpClientProbe {
    public static void main(String[] args) throws Exception {
        String url = args[0];
        boolean expectContinue = Boolean.parseBoolean(args[1]);
        String body = args.length > 2 && !args[2].isEmpty() ? args[2] : null;
        boolean chunked = Boolean.getBoolean("probe.chunked");

        RequestConfig requestConfig = RequestConfig.custom()
                .setExpectContinueEnabled(expectContinue)
                .build();
        try (CloseableHttpClient client = HttpClients.custom()
                .setDefaultRequestConfig(requestConfig)
                .build()) {
            HttpUriRequest request;
            if (body != null) {
                HttpPost post = new HttpPost(url);
                StringEntity entity = new StringEntity(body, "UTF-8");
                entity.setChunked(chunked);
                post.setEntity(entity);
                post.setHeader("Content-Type", "application/json");
                request = post;
            } else {
                request = new HttpGet(url);
            }

            try (CloseableHttpResponse response = client.execute(request)) {
                System.out.println("status: " + response.getStatusLine());
                HttpEntity entity = response.getEntity();
                System.out.println("body: " + (entity != null ? EntityUtils.toString(entity) : "<none>"));
            }
        }
    }
}
