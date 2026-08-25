# Cross-project lessons

Lessons from building `grid-meter-app` that are genuinely portable to the
other Java apps in this monorepo (`house-price-app`, `four-tier-app`,
`simple-app`), not specific to this app's own domain or scope. Unlike
`apps/.claude/settings.json`'s permission entries — which are literal
command strings tied to this app's exact ports, class names, and file
paths, and don't transfer as-is — these are the underlying practices and
gotchas behind those commands, written so they still apply once translated
to a different app's specifics. Each entry names the symptom, the fix, and
why it's not grid-meter-app-specific.

## Dependency and tool versions

**Verify a version against the real registry before pinning it, every
time — don't trust a plausible-looking string from training data or
memory.** This bit repeatedly across this project's history: a nonexistent
Docker image tag, a log-shipping agent (Promtail) that's actually been
removed upstream, Spring Boot property names that looked right but
weren't, and a Testcontainers major-version bump that silently needed
artifact-ID renames beyond just the version number (see below). The fix
each time was the same discipline: check `search.maven.org`, `npmjs.com`,
or the tool's own release page directly, not assume. `scripts/
check-maven-central-version.sh` exists specifically to make this cheap to
do for Maven artifacts.

**A major version bump can rename artifact IDs, not just change a version
string.** Testcontainers 1.x → 2.x (forced by a Docker Desktop update
raising the daemon's minimum accepted API version) renamed `junit-jupiter`
→ `testcontainers-junit-jupiter`, `postgresql` →
`testcontainers-postgresql`, `kafka` → `testcontainers-kafka`. A bare
version bump in `pom.xml` would have failed to resolve. Check a major
bump's actual release notes for renamed/split artifacts, not just its
version number.

**A tool your app's tests depend on doesn't have to match your app's own
pinned JDK/language version.** JMeter 5.6.3's bundled Groovy/ASM can't
compile JSR223 scripts under Java 25 (`Unsupported class file major
version 69`) even though the app itself targets Java 25 — JMeter needed
Java 21 specifically. This only surfaced on a real CI run, never
reproduced locally, because Homebrew's own `jmeter` formula hardcodes
`JAVA_HOME` to `openjdk@21` for this exact reason. When a host tool
(a load-test runner, a linter, a codegen tool) sits outside the app's own
build, verify its actual JDK/runtime requirement independently rather than
assuming it inherits the app's pin.

## Test-writing pitfalls

**Don't tamper with encoded/hashed data by flipping only its very last
character.** A `JwtServiceTest` here simulated a tampered signature by
flipping the last character of a base64-encoded HS256 hash. Base64
encoding of a fixed-length hash can leave the final character's low bits
as unused padding rather than real hash bits — flipping between two
specific characters sometimes changed only those padding bits, leaving the
"tampered" value byte-identical to the original and making the test
flaky (~1 run in 16, confirmed empirically). The general rule: when a test
needs to corrupt an encoded value to verify rejection, corrupt a
byte/character solidly in the interior of the encoded value, never the
literal last character of a base64 (or similar) string.

**A component test suite testing HTTP status codes should include the
framework's own internal error-dispatch path, not just your own routes.**
Spring Boot renders 404/405s via an internal forward to `/error`, which
re-enters the security filter chain as a fresh dispatch; a plain
`OncePerRequestFilter`-based auth filter doesn't re-run on that dispatch
type by default, so a real 404/405 can get silently overwritten with 401
by the auth entry point. The fix (`permitAll()` on `/error`) is a
well-known Spring Security + Boot interaction, but it's easy to miss
without a test that specifically checks a non-existent route or wrong
HTTP method's actual status code rather than assuming "not 200" is close
enough.

**A JVM HTTP test client can have its own footguns independent of the app
under test.** REST Assured's static `RestAssured.port` silently defaults
to 8080 and applies to any request URL that doesn't specify a port
explicitly — every black-box request in this project was landing on
Traefik's *dashboard* port instead of the real API, producing a
`Connection reset` that looked like a networking or Docker Desktop issue
and cost a full session to diagnose. When a black-box/API test library
behaves differently from `curl` against the identical running stack, the
library's own defaults (not just the environment) are a real suspect —
found here via a `tcpdump` packet capture comparing a working probe
against the failing one.

## Build tooling

**Mockito's inline-mock-maker self-attaching at runtime is a real,
fixable warning, not just noise to ignore.** Fixed with
`maven-dependency-plugin`'s `properties` goal (resolves `mockito-core`'s
jar path into a build property) plus a `maven-surefire-plugin` `argLine`
of `-javaagent:${org.mockito:mockito-core:jar}` — loads Mockito as a real
Java agent instead of the JDK-deprecated self-attach pattern. Generic
Maven/Surefire config, not Mockito-version-specific.

**Maven's nearest-wins dependency mediation can pull in a transitive
version your direct dependency doesn't actually support.** `rest-assured`
5.5.2 transitively pulls Groovy 5.0.6, which rest-assured itself doesn't
support yet (symptom: `NullPointerException` deep in Groovy's
`ClosureMetaClass` on some HTTP methods but not others). Fixed by pinning
the older, supported Groovy line as direct test-scope dependencies, which
wins under nearest-wins mediation. When a library's behavior is
inconsistent across similar calls (GET fails, POST works) with no obvious
reason in your own code, check `mvn dependency:tree` for a transitive
version your direct dependency wasn't built against.

## CI and process

**When promoting a CI job to a required branch-protection check, verify
that specific job's track record, not the overall workflow's.** A
workflow run can fail overall while the job you're about to promote was
green the whole time — the failure was in a different job. Check via `gh
api repos/{owner}/{repo}/actions/runs/{id}/jobs`, filtering to the
specific job name, across several recent runs, before promoting.

**`.claude/settings.local.json` accumulates literal one-off permission
entries fast during hands-on debugging sessions, and most of them are
dead weight within weeks.** Hardcoded UUIDs, session-specific `/tmp`
paths, and probe scripts for a since-resolved investigation don't match
any future invocation. Periodically trimming the file — and, where a
narrow entry represents a genuinely recurring *pattern* (e.g. "run one
specific test class by name"), generalizing it into a wildcard instead of
just deleting it — keeps the file useful rather than just growing. See
`status/claude_code_2026-08-24.md` for a concrete before/after (164 → 90
entries).

**Write non-trivial or multi-step commands to a committed script first,
then run the script — not a raw compound one-liner.** Easier for a
teammate (or a future session) to review, rerun, and diff; also matches
more cleanly against permission-allowlist patterns than an ad hoc chain of
`&&`-joined commands with inline flags that change slightly each time.
