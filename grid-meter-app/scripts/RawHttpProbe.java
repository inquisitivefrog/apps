import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.Socket;

/**
 * Sends a raw HTTP/1.1 request directly over a java.net.Socket, bypassing any HTTP client
 * library. Useful for isolating whether a connection issue (e.g. "Connection reset") is coming
 * from the server/network itself or from a specific HTTP client's own behavior — written while
 * diagnosing a REST Assured (Apache HttpClient) + Docker Desktop for Mac issue where curl and this
 * raw socket both succeeded talking to Traefik on localhost:80, but REST Assured's bundled client
 * did not. See MeterApiIT/ReadingApiIT's Javadoc for how that investigation concluded.
 *
 * Usage: java RawHttpProbe.java <host> <port> <method> <path> [json-body]
 */
public class RawHttpProbe {
    public static void main(String[] args) throws Exception {
        String host = args[0];
        int port = Integer.parseInt(args[1]);
        String method = args[2];
        String path = args[3];
        String body = args.length > 4 ? args[4] : "";

        try (Socket socket = new Socket(host, port)) {
            socket.setSoTimeout(5000);
            OutputStream out = socket.getOutputStream();
            StringBuilder request = new StringBuilder();
            request.append(method).append(' ').append(path).append(" HTTP/1.1\r\n");
            request.append("Host: ").append(host).append("\r\n");
            if (!body.isEmpty()) {
                request.append("Content-Type: application/json\r\n");
                request.append("Content-Length: ").append(body.getBytes().length).append("\r\n");
            }
            request.append("Connection: close\r\n\r\n");
            request.append(body);

            out.write(request.toString().getBytes());
            out.flush();

            BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            String line;
            while ((line = in.readLine()) != null) {
                System.out.println(line);
            }
        }
    }
}
