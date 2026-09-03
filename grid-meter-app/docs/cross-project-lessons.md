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

**For any Helm chart, verify the chart version's own bundled sub-chart
defaults, not just the top-level chart version.** A chart's *own* default
for a bundled dependency (e.g. `kube-prometheus-stack`'s default Grafana
sub-chart version) can silently drift ahead of whatever was pinned
elsewhere, even when the outer chart version looks stable — discovered
when a chart's default pulled Grafana 13.2.0 against this project's pinned
13.0.2, and the newer version's changed bootstrap behavior broke a
liveness-probe budget tuned against the older one. Check `helm show
values <chart>` (or the chart's own `Chart.yaml` dependencies) for actual
sub-chart versions before assuming a pinned application version travels
through a Helm chart unchanged.

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

## Shell scripting and OS-tooling pitfalls

**A script's own tooling assumptions can silently misbehave on macOS
instead of erroring loudly — and the real danger is when the script
doesn't notice.** Found twice independently in this project, in two
different chaos/test scripts, both the same underlying mistake: assuming
GNU coreutils behavior is universal when the dev machine runs macOS's
BSD userland instead.

- `timeout`/`gtimeout` don't exist on this machine at all by default — a
  write-refusal check silently no-op'd (`exit 127`) instead of running,
  and nothing downstream noticed, because the calling code treated "the
  check ran and passed" and "the check never ran" identically.
- `date +%s%3N` (millisecond timestamps) silently drops the `%3N` width
  modifier under macOS's BSD `date` — GNU-only syntax, not an error, just
  wrong output. That fed straight into bash arithmetic, which then
  failed and silently truncated a marker-write loop after its first
  iteration — while the script's own summary line still printed "5/5
  succeeded."

**The general lesson, in two parts.** First: verify a script's actual
tool/flag *behavior* with a real invocation on the machine it will
actually run on, not just a `command -v` existence check — a command
existing and a command behaving the way its GNU documentation describes
are two different questions on macOS, and the gap between them doesn't
announce itself. Second, and more important: any script whose "did this
actually work" logic depends on a shell built-in or coreutils command
producing a specific format needs its own sanity check on that output,
not a downstream success/failure branch that just trusts whatever the
tool happened to return. A script silently doing less than it claims
while still reporting success is a worse failure than an outright error,
because nothing signals that anything went wrong — this is the same
"fails open instead of loud" shape as the `timeout`/`gtimeout` case
above, not a coincidence that it happened twice.

**Never edit a script file while an invocation of it is still running.**
Bash reads a script incrementally as execution proceeds, not all at once
into memory — editing the file on disk mid-run can corrupt what the
*already-running* process reads for the remainder of its execution, even
though the file is syntactically correct both before and after the edit
and passes a syntax check afterward. Hit while iterating on a Kafka
chaos script: a fix was saved to disk while an earlier invocation of the
same script was still executing in the background, and that invocation
aborted mid-scenario with no indication the edit itself was the cause —
it looked like a runtime failure in the script's own logic. The general
rule: before modifying any script, confirm no background job is still
executing that exact file, regardless of how confident the edit itself
is.

**A chaos/monitoring script's own observation point can be invalidated
by the exact fault it's injecting, or by unrelated work elsewhere in the
project — check both, not just one.** Found twice in the same
investigation, two different mechanisms: a Kafka monitoring helper
hardcoded its query target to a specific broker, and the first run that
actually killed that broker had every poll during the outage silently
query a dead container — producing a false "no leader elected" result
that looked like a real failure but was actually the monitoring tool
losing its own vantage point. Separately, a different check in the same
script queried a standalone Postgres container that had been correctly
retired by an unrelated pass earlier in the same session — a
shared-infrastructure change with no visibility into what else referenced
it by name. The general rule, covering both: any script that queries
cluster/infrastructure state during a test needs a query path that
survives the exact fault being injected (dynamically pick a surviving
node, or route through a mechanism — a load balancer, service discovery
— built to tolerate any single node's death), and before retiring any
shared container or service, grep for its name across every other
script/pass in the project, not just the one currently being worked on.

**Same shape, different trigger: a breaking API-contract change's own
"who else calls this" audit needs to be a grep across the whole repo,
not a check against the endpoint's documented/remembered client list.**
Making an existing endpoint's header/parameter required (an idempotency
key on a POST endpoint) was closed out as "companion work done" after
updating the two *documented* clients (a JMeter load-test suite, a
Bruno API collection) — twice, in fact, the closure note was declared
complete and was wrong both times. What actually broke: six ad hoc
shell scripts, accumulated piecemeal across an unrelated multi-week HA
testing effort, that also called the endpoint directly but had never
been tracked as "a client of it" the way the two documented ones had.
Found only because one of the six happened to get run for an unrelated
reason and hit the new `400` directly — not because the audit caught
it. The general rule: "which clients call this endpoint" and "which
clients are we remembering/documenting as clients" are different sets
whenever ad hoc scripts can call a shared endpoint directly, and a
breaking-change audit that only checks the second set will look
complete while missing real callers. Before declaring a breaking
API/interface change's companion work finished, grep the whole repo for
literal calls to it (a URL path, a function name, an RPC method) rather
than working from a remembered or documented client list, and re-run
that grep again before the *second* time you're tempted to declare it
closed, too — closing it once wrong doesn't make the second closure
trustworthy by default.

**`grep -c PATTERN` exits non-zero when it finds zero matches, even
though it still correctly prints `"0"` — a real trap under `set -e`/
`pipefail`.** A count-based readiness check (`grep -c "^ip$"` counting
known replicas) copied `set -euo pipefail` from a different script's
pattern without checking it against this specific idiom. The first time
the count was legitimately zero, the pipeline's non-zero exit fed
straight into `-e` and killed the whole script silently, before its own
`if [ "$COUNT" -ge N ]` check ever ran — indistinguishable from the
script just hanging, with no error message pointing at the cause. Fixed
by dropping `-e` to match a sibling script's already-proven, deliberate
choice not to use it for exactly this class of readiness-polling logic,
rather than auditing every command substitution for this one gotcha.
General rule: `grep -c`, `grep -q`, and similar "exits non-zero on
legitimate no-match" commands are common inside readiness-polling loops
specifically because "not ready yet" is itself a normal, expected
outcome — which is exactly the case `set -e` cannot distinguish from a
real failure. Prefer `set -uo pipefail` (no `-e`) for scripts built
around this kind of polling, with explicit `if`/`until` checks doing the
control-flow work instead.

**A backgrounded loop (`&`) is still a subshell of its parent script and
still inherits `set -e` — the first command substitution to fail inside
it can kill the whole loop silently, with the parent script never
noticing.** A Postgres HA chaos script launched a continuous
request-generator function as a background job
(`send_requests_loop &`) to keep sending traffic while the foreground
script killed and monitored the primary. The loop's own `curl` call
returned non-zero on a genuine connection-refused during the failover
window — precisely the moment the test most needed data — and because
the backgrounded subshell inherited the parent's `set -e`, that single
non-zero exit killed the loop instantly after only ~2 seconds instead of
running its intended ~24-second window. The foreground script had no way
to see its background job had died early, so its own summary line still
printed a clean-looking result — the same "loop silently exits early,
script reports success anyway" shape `docs/testing-strategy.md`'s
fixed-sleep lesson already tracks, just triggered by `set -e`
propagating into a background job instead of a timing assumption. Root
cause of the regression, worth stating precisely since it's a distinct
mechanism from *introducing* an unguarded line: the loop's own
`|| echo "000"` fallback (present from the start, specifically for this
reason) was stripped out while fixing an unrelated cosmetic issue (a
doubled `"000000"` status code appearing in the log) — whoever made that
edit didn't recognize the same line was also the thing keeping `set -e`
from killing the loop. Caught by noticing one run's request count was
implausibly low for its duration, not by the script's own
still-clean-looking summary. **Distinct from the two set-e lessons
above, worth being precise about the difference**: the `grep -c` lesson
is about a command whose own zero-match exit code is a legitimate,
expected outcome `set -e` can't tell apart from failure; the
asymmetric-guard lesson (below, "Build tooling") is about one of two
adjacent, structurally-similar foreground lines getting a guard while
its neighbor didn't. This one is about `set -e`'s *scope* — a job
launched with a bare `&` is easy to mentally file as "off running on its
own," which is exactly what makes it easy to forget it's still bound by
the parent script's shell options. General rule: any command
substitution inside a function that will be launched as a background job
needs its own explicit guard, same as any substitution in the
foreground — and when removing what looks like a purely cosmetic
duplicate-output fix, check whether the line being touched is also
serving as an unrelated `set -e` guard before simplifying it away.

## Kubernetes and infrastructure-as-code pitfalls

**`docker compose rm -f -v` does not reliably delete a container's
anonymous volumes — but recreating the container still gets a genuinely
fresh one, which can mask the first fact if not checked directly.**
Found while building a real cold-bootstrap test for Patroni: the `-v`
flag left the old anonymous volumes orphaned/dangling rather than
removed, which could easily have invalidated the entire test (a "fresh"
bootstrap secretly reusing old data) if the new container had happened
to reuse one of them. It didn't — a container recreated without an
explicit volume mapping gets a brand-new anonymous volume regardless of
what `-v` did or didn't clean up — but this was confirmed directly
rather than assumed, since assuming it would have produced a
silently-invalid test with no indication anything was wrong. General
rule: when a test's validity depends on a truly clean data volume,
verify the volume is actually new (a fresh volume ID, an empty data
directory checked directly) rather than trusting a teardown command's
flags to have done what their names imply.

**A config language's comment syntax isn't universal — verify it per
language, not per project.** Alloy's River language uses `//` for
comments, not `#` — an easy assumption to get wrong coming from
YAML-heavy Kubernetes/Compose work, where `#` is nearly universal. A
`#`-prefixed line in a `.river` file isn't a comment, it's invalid syntax,
and crash-loops the container. The general rule: never assume a new
config language shares comment syntax with the languages around it —
check its own docs before writing the first comment.

**`ServiceMonitor.spec.selector` matches a `Service`'s `metadata.labels`,
not its `spec.selector`.** This is a widely-relearned Prometheus Operator
trap, not specific to this project: a `ServiceMonitor` written against a
`Service`'s *selector* (the labels it uses to find pods) silently matches
zero targets, because the `ServiceMonitor` is actually matching against
the `Service` object's own top-level labels instead. No error, no
warning — just an empty target list that looks like a scrape-config or
networking problem until traced back to this specific mismatch. Worth
checking this exact field relationship first, before assuming a
networking issue, any time a `ServiceMonitor`-based target shows as
missing.

**`hostPort` plus the default `RollingUpdate` strategy deadlocks a
single-node cluster.** A `Deployment` using `hostPort` binds that port on
the node itself, not just inside the pod — so a `RollingUpdate` (which
tries to start the new pod before terminating the old one) can never
schedule the replacement on a single-node cluster, since the port is
already held by the pod being replaced. The fix is `strategy: type:
Recreate`, not a `RollingUpdate` tuning parameter. General rule: any
`Deployment` using `hostPort` on a single-node target (a `kind` cluster,
a single-node k3s box) needs `Recreate`, not the k8s default — this isn't
specific to this project's manifests.

**Don't borrow a resource limit from a different environment's status log
by analogy — verify against this environment's own measured numbers.**
Compose's Grafana runs at 768m, but that number's real justification was
a *specific fixed bug* (a screenshot-automation script leaking 80–170MB
per run by opening a fresh browser session instead of reusing one) — not
"Grafana needs 768Mi to serve dashboards" in general. Applying that number
to a differently-loaded k8s Grafana pod (two sidecars in constant watch
mode, continuous alert evaluation, no screenshot automation at all) would
have been citing an unrelated precedent. The actual, correct fix came
from direct measurement (`memory.current`/`memory.max` from the pod's own
cgroup, found at 99.99% of a 256Mi limit) informing a new number (512Mi)
grounded in *this* workload — not a borrowed one. When a resource limit
elsewhere in the project looks like a ready-made answer, check what
specifically justified it before reusing it; a number and its reasoning
don't automatically transfer just because the component name matches.

**Alert rules (or any PromQL/query text) that hardcode one environment's
native label values silently break in a different environment with
different labels — normalize labels at scrape time, don't hardcode either
snapshot.** The same alert rules that worked against Compose's Prometheus
(`job="grid-meter-api"`, `service="api@docker"` — Traefik's Docker
provider naming) matched zero series once deployed against a k8s cluster,
where Prometheus Operator's `ServiceMonitor` defaults `job` to `api`, and
Traefik's k8s CRD provider generates an unstable, hash-suffixed `service`
value instead. The fix wasn't updating the rule text to k8s's values
either — that would just break Compose next time, and the CRD-generated
value isn't even guaranteed stable across an `IngressRoute` recreation.
The durable fix is a `relabelings`/`metricRelabelings` step at scrape
time in each environment's scrape config, normalizing every environment
toward one shared canonical label value — so the alert rule itself stays
environment-agnostic and only the scrape-time mapping differs per
environment. Applies to any project running the same alerting rules
across more than one deployment target.

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

**Correctly guarding one command substitution under `set -e` doesn't
mean its neighbor got the same treatment — check every one
individually.** A Postgres HA chaos script guarded a read check
(`RECOVERY=$(... 2>/dev/null || echo "unreachable")`) but left its
almost-identical sibling write check completely unguarded
(`WRITE_OUTPUT=$(... 2>&1)`, no `||`/`if` fallback). The failure
surfaced during a real Stage 4 run: a just-restarted node became
reachable enough to answer the guarded read query before it could
accept the unguarded write, and `set -e` killed the script on that
single unguarded line — silently, before the next line's diagnostic
`echo` ever printed, making the log look like nothing happened between
"not yet reachable" and the crash. **Distinct from the GNU-vs-BSD
tooling-assumption lessons above, worth being precise about the
difference**: those are genuinely platform-specific (a command or flag
behaves differently, or doesn't exist, depending on the OS). This one
is platform-agnostic — it would fail identically on Linux or macOS —
and is really an asymmetric-oversight bug: one of two nearly-identical
adjacent lines got a guard, the other didn't. The general rule: under
`set -e`, every command substitution that can plausibly fail needs its
own explicit guard, and writing a correct guard on one line is no
evidence the very next, structurally-similar line has one too — check
each command substitution on its own, don't infer safety by proximity.

**Never pipe the output of a script that mutates real infrastructure
state through something that can close its read side early (`| head
-N`, `| less`, etc.).** A Postgres HA chaos script's live output was
piped through `head -30` for a quick look, which triggered a `SIGPIPE`
once `head` stopped reading — killing the script outright before its
own cleanup/restore logic ever ran, leaving 2 Consul agents stopped
mid-test. Caught and manually restored immediately, but the general
risk is not specific to this one script: any pipe reader that can exit
before the writer finishes (`head`, `grep -m1`, a terminal pager) can
signal the writer to die at an arbitrary point, and a script performing
real mutations (starting/stopping infrastructure, writing data) needs
that mutation-and-cleanup sequence to complete regardless of whether
anyone is still watching its output. Redirect to a file and `tail`/`cat`
it separately instead of piping directly when the thing on the left is
mutating anything real.

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

**A long-running shell command that gets force-migrated from foreground
to background mid-run (after exceeding the tool environment's
foreground-execution window) can corrupt that script's own loop
execution — launch it as a background command from the start instead of
letting a timeout migrate it mid-way.** Found in a Postgres HA recovery
test: a monitoring loop silently stopped after a single iteration with
no error, initially misdiagnosed (in an earlier, similar-looking
incident) as a `date`/nanosecond-arithmetic bug and worked around by
switching to bash's `SECONDS` builtin for loop timing. The same failure
shape recurred later in a different loop that already used that fix,
which is what exposed the real mechanism: the underlying command had
been running long enough to hit the tool environment's own
foreground-timeout and got migrated to background execution partway
through, and that migration itself — not the loop's own timing logic —
disrupted execution. Confirmed by re-running the identical scenario
launched as a background command from the very start (no mid-run
migration): it completed cleanly. **Worth stating plainly**: the
original `SECONDS`-builtin fix likely treated a symptom of this same
migration, not its actual cause — an earlier explanation looked
reasonable at the time and turned out to be incomplete once more
evidence came in. Both times, the underlying operation had actually
completed correctly; the bug cost visibility into the result, not
correctness of the result itself. General rule: for any test or chaos
script expected to run long enough to risk hitting a tool's foreground
timeout, launch it as a background process from the start rather than
letting an automatic mid-run migration risk disrupting its internal
loop state.
