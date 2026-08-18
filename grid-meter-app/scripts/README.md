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

## Diagnostic HTTP probes

Written while chasing a `SocketException: Connection reset` that only
reproduces through REST Assured's bundled Apache HttpClient 4.5.13 against
the real stack (see the dated file under `status/` for the open
investigation) — each probe sends a request via a different HTTP stack to
narrow down which layer is responsible. Both `.java` files run via JDK
25's single-file source-launch mode, so there's no separate compile step.

- **`probe-raw-http.sh <host> <port> <method> <path> [json-body]`** /
  **`RawHttpProbe.java`** — sends a request directly over a bare
  `java.net.Socket`, bypassing any HTTP client library entirely. The most
  primitive probe; if this fails too, the problem isn't in any client
  library.
- **`probe-jdk-http-client.sh <url> [POST-json-body]`** /
  **`JdkHttpClientProbe.java`** — same request via the JDK's built-in
  `java.net.http.HttpClient`, one layer up from the raw socket.
- **`build-test-classpath.sh [output-file]`** — writes the `api` module's
  full test-scope Maven classpath to a file (default
  `/tmp/grid-meter-api-test-classpath.txt`). Not a probe itself, but
  supports writing further ad hoc diagnostic Java programs that need the
  exact same dependency versions (e.g. Apache HttpClient 4.5.13 itself)
  as the real test suite.

Both curl and both custom probes above work fine against the same running
stack; only REST Assured's client fails — see the status log for the
current state of that investigation.
