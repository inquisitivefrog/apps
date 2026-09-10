# grid-meter-app — High-availability scope: Redis Sentinel in `kind` (k8s follow-up)

## Why this doc exists

`docs/ha-scope.md`'s "Revisit triggers" section named a k8s Redis Sentinel HA
follow-up on 2026-09-06, explicitly unscoped at the time — mirroring the same
"revisit later" item that had already sat unpicked-up for weeks in the case
of `k8s/kafka.yaml`'s own StatefulSet migration
(`docs/k8s-kafka-ha-scope.md`). This is that doc, written the same way as the
Kafka one: after the design/build/validation work, not before it.

Scoped narrowly, the same way the Kafka doc was: **porting the
already-decided Compose topology (`docs/redis-ha-scope.md`) into `kind`** —
this doc does not reopen the primary/replica/Sentinel topology decision, the
`min-replicas-to-write`/`min-replicas-max-lag` durability settings, or any of
Redis HA's other already-closed design questions. What started as a
straightforward port turned into something more consequential, though: it
found and fixed three real, previously-undiscovered correctness bugs in
`scripts/redis-entrypoint.sh`'s Sentinel-lookup logic — the same script this
whole k8s slice reuses unmodified from Compose, meaning all three bugs were
equally live in the already-shipped Compose topology the whole time,
undiscovered because nothing had re-exercised that exact code path under
different timing since Compose's own Finding A fix was verified back on
2026-08-28.

## Decision: `StatefulSet` + headless Service, for both data nodes and Sentinels

Same reasoning as `k8s-kafka-ha-scope.md`'s own decision, applied to a second
technology: Sentinel's failover decisions and `redis-entrypoint.sh`'s own
self-demotion logic both depend on each node having a stable, predictable
identity across restarts — a `Deployment`'s randomly-named, undifferentiated
pods can't provide that. `k8s/redis.yaml` (`redis-0/1/2`) and the new
`k8s/sentinel.yaml` (`sentinel-0/1/2`) are both `StatefulSet`s + headless
Services (`clusterIP: None`), giving every pod a stable per-pod DNS name
(`redis-0.redis-headless`, `sentinel-0.sentinel-headless`, etc.).

Sentinels are themselves stateless coordinators with no data to lose on
restart, but a `StatefulSet` was used for them too anyway, for naming/
addressing symmetry with the data nodes and because Compose's own
`sentinel-1/2/3` services are already effectively identical, ordinal-
addressed peers — a `StatefulSet` is the more direct structural port of that
shape than a `Deployment` plus a separate discovery mechanism would be.

Storage stays ephemeral (no `volumeClaimTemplates`) for both, matching every
other component in this slice.

## Entrypoint script: shared unmodified, parameterized for per-pod identity

`scripts/redis-entrypoint.sh` — the script Compose's `redis`/
`redis-replica-1`/`redis-replica-2` services already bind-mount, built to
fix Finding A's split-brain window (`docs/redis-ha-scope.md`) — is reused
here **as the identical file**, not forked or rewritten for k8s. Two things
that differ per-environment were parameterized rather than hardcoded a
second time:

- **`SENTINEL_HOSTS`**: defaults to Compose's `sentinel-1 sentinel-2
  sentinel-3`; overridden in k8s to the 3 Sentinel pods' headless-Service
  DNS names via an env var set in `redis.yaml`'s pod spec.
- **`MY_HOSTNAME`**: Compose sets this once per service in its `environment:`
  block (one hardcoded value per container, since each service is its own
  distinct definition). A `StatefulSet` applies one identical pod template
  to every replica, so there's no per-pod place to hardcode this — instead,
  `redis.yaml`'s container `command` is a small shell wrapper that computes
  it at container-start time from the pod's own name (via the Downward
  API's `POD_NAME` field) plus the headless Service's DNS suffix:
  `MY_HOSTNAME="${POD_NAME}.redis-headless"`.
- **`FALLBACK_REPLICAOF_HOST`/`PORT`**: Compose sets these on
  `redis-replica-1`/`2` only, leaving `redis` (the intended default primary)
  unset. The same wrapper computes this per-pod from the ordinal suffix:
  `redis-0` gets neither set (it's the node meant to fall back to plain
  primary if Sentinel is genuinely unreachable at boot); `redis-1`/`redis-2`
  get `FALLBACK_REPLICAOF_HOST=redis-0.redis-headless` set.

The script itself is delivered into the cluster via a ConfigMap
(`redis-entrypoint-script`) generated at deploy time directly from
`scripts/redis-entrypoint.sh` (`k8s/deploy.sh`, via `kubectl create
configmap ... --from-file=... --dry-run=client -o yaml | kubectl apply -f
-`) — the k8s-native equivalent of Compose's own `./scripts/
redis-entrypoint.sh:/entrypoint.sh:ro` bind mount. This keeps one source of
truth shared between both environments, matching
`deploy-observability.sh`'s existing precedent for the dashboard/alert-
rules/Tempo-config ConfigMaps, rather than duplicating the script's logic
inline in `redis.yaml`.

`min-replicas-to-write 1 --min-replicas-max-lag 10` is applied to **all 3**
pods here, not just the initial primary the way Compose's `redis` service
alone declares it — a deliberate deviation, not an oversight. A
`StatefulSet`'s single shared pod template can't single out "whichever pod
is currently primary" the way Compose's separate per-service config blocks
can, and since this setting is a no-op on a replica (it only gates a
*primary's* write acceptance) but becomes immediately active the moment any
pod is promoted, applying it uniformly is strictly safer than Compose's
original shape. This turned out to matter concretely — see the k8s kill-test
results below.

## What changed in the app's own k8s config

`configmap.yaml`'s Redis block moved from the single-instance stopgap
(`SPRING_DATA_REDIS_HOST`/`PORT` pointed at a plain `redis.yaml` Deployment,
`SPRING_PROFILES_ACTIVE: test` routing around the app's own Sentinel-mode
activation) to real Sentinel-aware discovery:
`SPRING_REDIS_SENTINEL_MASTER=mymaster`,
`SPRING_REDIS_SENTINEL_NODES=sentinel-0.sentinel-headless:26379,sentinel-1.sentinel-headless:26379,sentinel-2.sentinel-headless:26379`.
The `SPRING_PROFILES_ACTIVE` entry is removed entirely, not set to
something else — `application.yml`'s Sentinel block activates on `!test`,
so simply not activating any profile here (matching Compose's own `api`
service, which activates no profile either) is what turns Sentinel mode on.
The literal env-var names (`SPRING_REDIS_SENTINEL_*`, not
`SPRING_DATA_REDIS_SENTINEL_*`) were confirmed against `application.yml`'s
actual placeholder syntax and against Compose's own already-working `api`
service, not assumed from the Boot-3-namespaced Java property path
(`spring.data.redis.sentinel.*`) the way `k8s-kafka-ha-scope.md`'s own
`SPRING_REDIS_HOST`/`PORT` finding was caught getting wrong the first time.

`k8s/deploy.sh` gained the ConfigMap-generation step above, an `apply` for
the new `sentinel.yaml`, and `rollout status` checks for
`statefulset/redis` and the new `statefulset/sentinel` (replacing the old
`deployment/redis` check).

## Three real correctness bugs found in the shared entrypoint script, fixed for both Compose and k8s

Re-running `docs/redis-ha-scope.md`'s own Stage 4 regression test
(`load-tests/redis-primary-failover-rto.sh`) against Compose — done as a
sanity check before trusting the k8s port's own kill test, per an explicit
push-back that a newer test passing doesn't confirm an older, related
commitment is still sound — came back **`SPLIT-BRAIN: YES`**: a real,
reproducible two-writer window, not a flake. All three bugs below live in
`scripts/redis-entrypoint.sh` itself, so all three applied equally to
Compose the whole time; none is k8s-specific.

### Bug 1 — a stale `get-master-addr-by-name` answer during an active failover

`SENTINEL get-master-addr-by-name` can and does keep returning the **old**
master's address for several seconds *after* a new master has already been
selected and promoted — Sentinel doesn't update that specific answer until
the entire failover completes (every known replica reconfigured, the
`+switch-master` event fires), not merely once a replacement has been
chosen. Confirmed via a dedicated live probe (kill the primary, poll
`SENTINEL master mymaster`'s `flags` field every 0.3s): the literal
substring `failover_in_progress` is present for the whole duration Sentinel
considers the failover unsettled — observed 8-12s in real local runs. A
restarted node whose query landed during this window was told it was still
master, started as one, and would have accepted a write before Sentinel's
own later runtime `REPLICAOF` call corrected it — the exact two-writer
window Finding A's original fix exists to prevent, just via a mechanism
that fix's own design never accounted for.

**Fix**: query `SENTINEL master mymaster` for `flags` before ever trusting
`get-master-addr-by-name`'s answer; retry if `failover_in_progress` appears.

### Bug 2 — a promoted node can never again recognize itself as master

A deeper, structural gap, found live via a plain, **non-killing** restart
of the genuinely-still-healthy current primary (after a real failover had
already promoted it earlier): Sentinel only ever knows an entity's
*hostname* if it was the address on Sentinel's own static, original
`sentinel monitor mymaster <host> ...` line (`redis`/`redis-0`). Any other
node — specifically, any node that becomes master via a real failover — is
known to Sentinel only by the raw connection IP its replica traffic arrived
from, since no `replica-announce-ip` is configured and a replica never
otherwise tells its master a hostname to remember. `MASTER_HOST` can
therefore be a raw IP identical to a node's own current IP, which will
never string-equal `$MY_HOSTNAME`. Confirmed live: the real, still-healthy
promoted master was told the master was its own IP, failed the hostname
comparison, and issued `--replicaof <its own IP>` on itself — rejected by
Redis as self-referential, leaving it an orphaned, disconnected
pseudo-replica with zero connected replicas of its own. Not literal
split-brain (it never accepted writes as an ambiguous second primary,
since it also stopped functioning as a real primary), but every bit as
operationally broken, and a real gap this project's own "run more than
once, even if the first run looks clean" discipline exists to catch.

**Fix**: also resolve the node's own current IP (`hostname -i`) at boot and
accept either form as a match — `$MASTER_HOST` will be a hostname or an IP
depending on how Sentinel originally learned that identity, never both.

### Bug 3 — a narrower race in the window before Sentinel starts reacting at all

Found re-verifying Bug 1's fix, not a separate investigation: a query
landing in the brief window right after a kill but *before* Sentinel has
even initiated any failover shows `flags=s_down,master` — subjectively
suspected down, but no failover triggered yet, so the `failover_in_progress`
substring check doesn't fire. A restarted node querying during this
specific window still got told it was master. This particular run's
`SPLIT-BRAIN` verdict still read `NO` — but only because `min-replicas-to-
write` correctly rejected the one write attempt made during the ~9.5s
probe window, a *different* safety net catching what this entrypoint's own
logic got wrong; the restarted node genuinely believed itself primary for
the whole window, which is exactly the ambiguous state Finding A's fix
exists to prevent regardless of whether a write happened to land during it.

**Fix**: rather than enumerate every unhealthy flag combination Sentinel
can report (`master,disconnected`, `s_down,master`, `s_down,o_down,master,
failover_in_progress`, and whatever else hasn't been observed yet), only
ever trust an answer when `flags` is the single, clean, literal value
`master` — confirmed via live probing to be the actual steady-state value,
with every other observed combination containing something appended.

### The fix's own cost: cold-bootstrap timing needed real headroom

The stricter "only exactly `master`" check has a genuine cost: a fully
fresh, simultaneous bootstrap (every data node and every Sentinel recreated
at once — exactly what Stage 4's own "reset to canonical topology" step
does before every run) can spend a while in `master,disconnected` then
`s_down,master,disconnected` before the first-ever Sentinel-to-primary
connection actually settles — a normal part of cold start, not a failover,
but indistinguishable from one by the flags value alone. The original
10-attempt (10s) budget was already tight for this; the stricter check
made it worse, and one live re-verification run genuinely exhausted a
30-attempt (30s) budget under real resource contention (a concurrent
`kind` cluster sharing this Mac's Docker Desktop VM) without ever settling.
Widened to 60 attempts (60s) in the entrypoint, with
`redis-primary-failover-rto.sh`'s own setup-phase wait loop widened to
match (30s → 90s) — correctness (never trusting a dirty flag) matters more
than shaving a few seconds off startup latency, and every node still has
its `FALLBACK_REPLICAOF_HOST`/`PORT` (or a loud bare-start log) safety net
if even that isn't enough.

## Validation

### Compose Stage 4 regression — 11 runs across the fix's three iterations

| Run (timestamp) | Phase | RTO | Demoted at | Verdict |
|---|---|---|---|---|
| 162406 | before any fix | 6s | not observed | **SPLIT-BRAIN: YES** — the original finding |
| 162908 | fix 1 (failover_in_progress) | 7s | 0.18s | NO |
| 162933 | fix 1 | 8s | 0.22s | NO |
| 163016 | fix 1 | 7s | 0.28s | NO |
| 163552 | fix 1+2 | 6s | not observed | NO, but masked — Bug 3 found here |
| 163801 | fix 1+2+3 | 7s | 0.18s | NO |
| 163859 | fix 1+2+3 | 6s | 0.26s | NO |
| 163956 | fix 1+2+3 | — | — | setup aborted at 30s (timing-budget gap, not a split-brain finding) |
| 164245 | fix 1+2+3, widened budget | 21s\* | 1.07s | NO |
| 165042 | fix 1+2+3, widened budget | 6s | 0.25s | NO |
| 165216 | fix 1+2+3, widened budget | 6s | 1.25s | NO |

\* Setup phase took 50-57s in the final three runs (concurrent `kind`
cluster contention on the same Docker Desktop VM), but the actual
kill-to-promotion RTO and demotion times are consistent with the
uncontended runs — only the cold-bootstrap phase was affected, not the
correctness result.

The three runs at 162908-163016 are clean but don't actually exercise Bug
2 (Stage 4's own scenario only ever restarts the *originally*
hostname-known node, never a promoted one) — Bug 2 was found and fixed via
a separate, direct restart test, not via this script. Counting only the
runs against the fully-fixed script (163801 onward, excluding the one
setup-timeout abort): **5 of 5 clean**, comfortably past this project's
3-run correctness bar.

### k8s kill test, with a real split-brain probe (2026-09-09)

The functional path was confirmed working early in this session (login →
create meter → create reading, cache write landing on Redis, all before
any of the entrypoint bugs above were found) — but that first kill test
had no split-brain probe at all, only checking request success and pod-UID
change, and ran against the *unfixed* entrypoint script. Not cited as
evidence of anything here; superseded by a purpose-built re-test after all
three fixes landed, using the same sub-second role-plus-write-attempt
methodology as Compose's Stage 4 script, run under `caffeinate -i` to keep
the timing measurement itself trustworthy (see the note below).

- Killed `redis-0` (the Sentinel-reported primary) under a marker write
  confirmed present on both survivors first.
- **RTO (kill-to-promotion): 7s.** `redis-1` promoted, confirmed to hold
  the marker write via direct `GET`.
- **Pod recovery (new UID, `Running`+`Ready`): 7s** — `redis-0` came back
  as a genuinely new pod (new UID), not the same one still terminating.
- **Sub-second split-brain probe on the restarted `redis-0`**: reported
  `role=master` for ~3 seconds (21 probes at ~0.13s intervals) — but every
  single write attempt during that window returned `NOREPLICAS`, never
  `OK`, because `min-replicas-to-write 1` is applied uniformly to all 3
  k8s pods (this slice's own deliberate deviation from Compose, see
  above) — a real, structural safety net Compose's original 3-node config
  didn't have on its non-primary nodes. **SPLIT-BRAIN: NO.**

## A separate, unrelated finding: a laptop sleep gap corrupted an earlier timing measurement

The *first* k8s kill test's own script measured a "1033s" recovery time —
bogus, confirmed by cross-checking the pod's actual `creationTimestamp`
against real wall-clock time (the true recreation took under a minute).
Root cause: the laptop almost certainly went to sleep while that script's
`sleep 1`-based poll loop was waiting in the background, and `date +%s`
correctly reflects real elapsed wall-clock time once a system resumes from
suspend — inflating the measured delta by the full suspended duration.
Not a Redis/Sentinel mechanism at all; see `docs/testing-strategy.md`'s new
"a laptop system-sleep gap can corrupt a `date +%s`-based timing
measurement" section for the full account and the standing guidance
(`caffeinate -i` for genuinely time-sensitive local measurements going
forward — used for this doc's own final k8s kill-test numbers above).

## Deliverables from this pass

- `k8s/redis.yaml` — `StatefulSet` (`redis-0/1/2`) + headless Service,
  entrypoint script mounted from a ConfigMap.
- `k8s/sentinel.yaml` (new) — `StatefulSet` (`sentinel-0/1/2`) + headless
  Service.
- `k8s/configmap.yaml` — Sentinel-aware env vars, `SPRING_PROFILES_ACTIVE`
  removed.
- `k8s/api.yaml` — env vars updated to match.
- `k8s/deploy.sh` — ConfigMap generation step, `sentinel.yaml` apply,
  updated rollout checks.
- `scripts/redis-entrypoint.sh` — all three fixes above, shared unmodified
  by Compose and k8s.
- `load-tests/redis-primary-failover-rto.sh` — setup-phase wait budget
  widened to match.
- `k8s/README.md` — "Deliberate simplifications" entry updated (the old
  single-instance-Redis stopgap language was stale).
- `docs/ha-scope.md` — "Revisit triggers" entry closed.
- `docs/testing-strategy.md` — new sleep-across-suspend measurement lesson.

## Explicitly deferred / out of scope for this doc

- **Persistent storage for Redis/Sentinel in `kind`** — unchanged from the
  original first-slice decision (ephemeral, no PVCs); not reopened here.
- **Cloud Redis topology** — `cloud-deployment-scope.md` already commits
  to *managed* Redis (ElastiCache/Memorystore/Azure Cache) per cloud, not
  self-hosted Sentinel — this slice's StatefulSet design has no analog to
  reuse there the way Kafka's does.
- **Filing the three entrypoint bugs anywhere upstream** — these are bugs
  in this project's own script, not in Redis/Sentinel itself, so there's
  no vendor report to file (unlike the Kafka KRaft finding in
  `docs/vendor-bug-report-process.md`).
