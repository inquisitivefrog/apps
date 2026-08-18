# scripts/

Standalone helper scripts for this repo — pulled out of one-off shell
invocations so repeated multi-step commands are reviewable, reusable, and
easy for `.claude/settings.local.json` to allowlist. Each script also
carries its own header comment; this file is the index.

## Dependency version verification

- **`check-maven-central-version.sh <groupId> <artifactId> [rows]`** —
  prints the most recent published versions for a Maven Central artifact.
  Used to verify a dependency is actually current before pinning it, per
  this repo's version-verification convention (see
  `docs/tech-stack-versions.md`).

## Ad hoc auth/security verification

- **`verify-auth-security.sh [base-url]`** — curl-based smoke check against a running
  `docker compose up` stack (default `http://localhost`, i.e. through Traefik) covering the auth/
  security behaviors most likely to get typed inline as one-off curl calls: actuator staying open,
  unauthenticated/invalid-token rejection, a real login, and `PUT /readings/{id}` returning 405
  (readings are immutable — see `docs/api-and-data-model.md`). The real, CI-gated source of truth
  for this behavior is the REST Assured suite (`ApiSecurityComponentTest`,
  `ReadingApiTestBase.putReading_isRejectedWith405`) run via `mvn test` — this script is only for a
  quick manual check without retyping a compound curl chain each time.

## Black-box API test tier

These support the `*ApiIT` suite (`api/src/test/java/com/gridmeter/api/
{meter,reading}`) — the Failsafe-bound tier that runs black-box HTTP calls
against a real deployed stack, as opposed to the embedded-server
`*ApiComponentTest` tier that runs via Surefire on every push. See
`docs/testing-strategy.md` for why both tiers exist.

- **`run-black-box-api-tests.sh`** — brings up the traefik/api/postgres/
  kafka/redis tier via Docker Compose, waits for the API to report healthy
  through Traefik, then runs the `*ApiIT` suite with
  `test-compile failsafe:integration-test failsafe:verify` (deliberately
  not `mvn verify` — that would also trigger Surefire, and not
  `-DskipTests`, which skips Failsafe too since it shares that property
  with Surefire by design). Does **not** tear the stack down afterward —
  left running for local debugging; run `docker compose down` manually
  when done.
- **`wait-for-health.sh [url] [timeout-seconds]`** — polls a health-check
  URL until it responds successfully or the timeout elapses. Defaults to
  `http://localhost/actuator/health`, 90s. Used by
  `run-black-box-api-tests.sh` and intended for reuse in CI once the
  black-box job is wired up.

## Diagnostic HTTP probes (investigation resolved)

Written while chasing a `SocketException: Connection reset` that only
reproduced through REST Assured's black-box `*ApiIT` tier against the real
stack. **Resolved**: REST Assured's static `RestAssured.port` defaults to
8080 and gets silently applied whenever a request's URL doesn't carry an
explicit port — every black-box request was actually landing on Traefik's
*dashboard* port (8080), which reset the connection, not the real API on
port 80. Fixed in `MeterApiIT`/`ReadingApiIT` by deriving `RestAssured.port`
explicitly from the configured base URL; see those classes' Javadoc for the
full writeup. Each probe below sends the same request via a different HTTP
stack, which is how the layers were ruled out one at a time before a packet
capture pinned down the actual port mismatch. `.java` files run via JDK
25's single-file source-launch mode, so there's no separate compile step.
Kept around as reusable diagnostics for the next time an HTTP-layer mystery
shows up.

- **`probe-raw-http.sh <host> <port> <method> <path> [json-body]`** /
  **`RawHttpProbe.java`** — sends a request directly over a bare
  `java.net.Socket`, bypassing any HTTP client library entirely. The most
  primitive probe; if this fails too, the problem isn't in any client
  library.
- **`probe-jdk-http-client.sh <url> [POST-json-body]`** /
  **`JdkHttpClientProbe.java`** — same request via the JDK's built-in
  `java.net.http.HttpClient`, one layer up from the raw socket.
- **`probe-apache-http-client.sh <url> <expect-continue:true|false> [POST-json-body] [classpath-file]`**
  / **`ApacheHttpClientProbe.java`** — same request via Apache HttpClient
  4.5.13's modern (4.3+) `HttpClients.custom()`/`RequestConfig` builder —
  the same library/version REST Assured bundles internally, but its
  current-generation execution path. Set `CHUNKED=1` to send the body as
  chunked transfer-encoding instead of fixed-length.
- **`probe-apache-http-client-legacy.sh <url> <expect-continue:true|false> [POST-json-body] [classpath-file]`**
  / **`ApacheHttpClientLegacyProbe.java`** — same request via Apache
  HttpClient's deprecated `DefaultHttpClient`/`DefaultRequestDirector`
  execution path and old `HttpParams` config API — the exact internal
  class REST Assured's Groovy `HTTPBuilder` layer actually constructs.
- **`probe-restassured-minimal.sh <url> [POST-json-body] [classpath-file]`**
  / **`RestAssuredMinimalProbe.java`** — sends the request via bare REST
  Assured itself (no Spring, no test scaffolding), the probe that actually
  reproduced the failure and proved it was REST Assured's own layer, not
  Apache HttpClient in any configuration. Set `WIRE_DEBUG=1` for Apache
  HttpClient wire-level logging (didn't end up showing the port mismatch,
  since commons-logging routing didn't cooperate here, but left in for
  future use).
- **`capture-connection-reset.sh [pcap-output-file]`** — the script that
  found the actual root cause: runs a known-working probe and the failing
  REST Assured probe back to back while `tcpdump` captures loopback
  traffic (all ports — the original port-80-only filter missed the
  failing connection entirely, since it was going to 8080). Needs `sudo`;
  run directly in a real terminal, not through an automated tool, since
  `sudo` needs an interactive password prompt.
- **`build-test-classpath.sh [output-file]`** — writes the `api` module's
  full test-scope Maven classpath to a file (default
  `/tmp/grid-meter-api-test-classpath.txt`). Not a probe itself, but
  supports writing further ad hoc diagnostic Java programs that need the
  exact same dependency versions (e.g. Apache HttpClient 4.5.13 itself)
  as the real test suite. Run this first — all the probes above expect the
  classpath file it produces.
