import org.apache.http.HttpEntity;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.client.methods.HttpUriRequest;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.params.CoreProtocolPNames;
import org.apache.http.util.EntityUtils;

/**
 * Sends a request via Apache HttpClient's legacy {@code DefaultHttpClient}/{@code
 * DefaultRequestDirector} execution path (deprecated since 4.3, but still present in 4.5.13) and
 * the old {@code HttpParams}-based config API — matching what REST Assured's Groovy
 * {@code HTTPBuilder} layer actually constructs internally, and exactly how
 * {@code HttpClientConfig.setParam("http.protocol.expect-continue", false)} sets it
 * ({@code client.getParams().setParameter(...)}) — as opposed to ApacheHttpClientProbe.java, which
 * uses the modern (4.3+) {@code HttpClients.custom()}/{@code RequestConfig} builder that REST
 * Assured does NOT use. If this reproduces the "Connection reset" that
 * ApacheHttpClientProbe.java's modern client did not, it isolates the failure to this specific
 * legacy execution path rather than to Apache HttpClient / Expect-Continue in general. See the
 * dated file under status/ for where this investigation stands.
 *
 * Usage: java ApacheHttpClientLegacyProbe.java <url> <expect-continue:true|false> [POST-json-body]
 */
public class ApacheHttpClientLegacyProbe {
    public static void main(String[] args) throws Exception {
        String url = args[0];
        boolean expectContinue = Boolean.parseBoolean(args[1]);
        String body = args.length > 2 && !args[2].isEmpty() ? args[2] : null;

        DefaultHttpClient client = new DefaultHttpClient();
        client.getParams().setBooleanParameter(CoreProtocolPNames.USE_EXPECT_CONTINUE, expectContinue);
        try {
            HttpUriRequest request;
            if (body != null) {
                HttpPost post = new HttpPost(url);
                post.setEntity(new StringEntity(body, "UTF-8"));
                post.setHeader("Content-Type", "application/json");
                request = post;
            } else {
                request = new HttpGet(url);
            }

            org.apache.http.HttpResponse response = client.execute(request);
            System.out.println("status: " + response.getStatusLine());
            HttpEntity entity = response.getEntity();
            System.out.println("body: " + (entity != null ? EntityUtils.toString(entity) : "<none>"));
        } finally {
            client.getConnectionManager().shutdown();
        }
    }
}
