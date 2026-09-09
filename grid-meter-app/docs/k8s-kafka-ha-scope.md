# grid-meter-app — High-availability scope: Kafka in `kind` (k8s follow-up)

## Why this doc exists

`k8s-terraform-decisions-2026-08-19.md` deliberately shipped `k8s/kafka.yaml`
as a single-broker `Deployment` in the first `kind` slice, explicitly
deferring multi-broker HA to a follow-up. That follow-up sat as an
unscoped "revisit later" item in status logs from 2026-08-27 through
2026-09-06 with no supporting design doc — every other HA investigation in
this project (Kafka on Compose, Redis, Postgres) got a durable
`*-ha-scope.md` doc; this is that doc for the k8s-specific slice, written
after the fact from the design/build/validation work rather than before it,
since the work itself was done and closed in a single 2026-09-06 session.

This doc is scoped narrowly to **porting the already-decided Compose
topology into `kind`** — it does not reopen any decision `ha-scope.md`
already made (3 brokers, KRaft quorum voters, `acks=all`,
`min.insync.replicas=2`). The only new questions here are k8s-native ones:
how does a `StatefulSet` provide what `docker-compose.yml`'s named
containers (`kafka-1`/`kafka-2`/`kafka-3`) already gave the Compose version
for free.

## Decision: `StatefulSet` + headless Service, not a `Deployment`

A `Deployment` with `replicas: 3` has no concept of "the second replica" —
pod names are random suffixes, there's no stable per-pod identity, and a
plain (load-balancing) Service in front of them would imply a client could
talk to any one transparently. None of that matches what KRaft's quorum
voter mechanism actually needs: each broker/controller needs to know the
other two by a *stable* address, before and after any pod restart.

A `StatefulSet` + headless Service (`clusterIP: None`) solves this
directly: ordinal pod naming (`kafka-0`, `kafka-1`, `kafka-2`) gives each
broker a name that survives rescheduling, and the headless Service gives
each pod its own resolvable per-pod DNS name
(`kafka-0.kafka.default.svc.cluster.local`, etc.) rather than one shared
load-balanced name. This is the general answer to "how do stateful peers
find each other in k8s" — name-based addressing backed by a headless
Service's stable DNS, not IP-based — not a Kafka-specific trick, and worth
keeping as the default pattern for any future stateful k8s work in this
project.

**The redundant plain (load-balancing) Kafka Service was deliberately
dropped**, not merely left out — an earlier draft of the manifests still
had one. A load-balancing Service in front of 3 KRaft brokers would imply
a client could talk to any one interchangeably, which isn't how the
protocol works (a client needs the bootstrap list, then talks to whichever
broker actually leads the partition it wants). Removing it was a
correctness fix, not tidying.

## Node ID derivation: shell wrapper, not manifest templating

Two different mechanisms were needed, and it matters which:

- **`KAFKA_ADVERTISED_LISTENERS` and `KAFKA_CONTROLLER_QUORUM_VOTERS`** are
  pure manifest templating — replica count and pod names are fixed and
  known upfront (`kafka-0/1/2`), so the full voter list can just be written
  out directly in the ConfigMap/StatefulSet spec using Kubernetes' own
  `$(VAR)` env interpolation.
- **`KAFKA_NODE_ID`** needs a small startup-command wrapper
  (`${HOSTNAME##*-}`, extracting the ordinal suffix from the pod's own
  hostname) — confirmed live via `docker inspect`/`configure` that the
  Kafka image itself has no Kubernetes/hostname awareness; a
  `StatefulSet`'s pod hostname *is* its name (`kafka-0`, not a random
  suffix), which is exactly what makes this trick work at all.

**Node IDs are 0-indexed** (`kafka-0`/`1`/`2`), not matching Compose's
1-indexed `kafka-1`/`2`/`3` — a deliberate, minor decision rather than an
inherited default: 0-indexing is simpler in k8s (matches `StatefulSet`
ordinals directly with no offset math) and there's no correctness reason
to force cosmetic parity with Compose.

## What changed in the app's own k8s config

Per this project's standing "chaos-tested infrastructure ≠ protected
application" lesson (`CLAUDE.md`), checked proactively this time rather
than found after the fact: `configmap.yaml`'s
`SPRING_KAFKA_BOOTSTRAP_SERVERS` was the one app-facing value needing an
update, from the single-broker `kafka:9092` to all three pods by their
headless-Service DNS names, matching Compose's proven
`kafka-1,kafka-2,kafka-3` shape.

## Two pre-existing, Kafka-unrelated bugs found and fixed along the way

Neither of these was caused by this slice's work — both were found because
this was the first time the full app had actually run in `kind` since an
earlier code change landed, and nobody had re-run it end-to-end since:

- **k8s's Redis was never updated after the app's Redis Sentinel cutover**
  (`ha-scope.md`'s local Redis HA pass) — `application.yml` activates
  Sentinel mode for every Spring profile except `test`, but `k8s/redis.yaml`
  is still a single plain Deployment with no Sentinels to discover, so the
  app crash-looped against a Sentinel address that never existed in
  k8s. Fixed as an explicit, labeled setting: `SPRING_PROFILES_ACTIVE: test`
  in `k8s/api.yaml` — not a silent workaround, documented in
  `k8s/README.md`'s "Deliberate simplifications" section.
- **`SPRING_REDIS_HOST`/`PORT`** in the ConfigMap were the pre-Spring-Boot-3
  property names, silently binding to nothing (Boot 3+ moved this under
  `spring.data.redis.*`). Renamed to `SPRING_DATA_REDIS_HOST`/`PORT`.
  Caught a real self-verification mistake in the process: a clean-looking
  pod log was initially trusted as confirmation the profile fix had taken
  effect; direct `kubectl exec ... env | grep` showed it hadn't actually
  been wired into `api.yaml` yet. Fixed once verified properly.

**This surfaces a genuine, durably-tracked follow-up**: a real k8s Redis
Sentinel HA pass, mirroring this doc's own Kafka work — `k8s/redis.yaml`
would need the same StatefulSet + headless Service treatment, plus removing
the `SPRING_PROFILES_ACTIVE: test` workaround once real Sentinels exist to
discover. Tracked in `ha-scope.md`'s "Revisit triggers" section, not
scoped here — recorded there specifically so it doesn't sit dormant the
way this Kafka slice itself did for several weeks.

## Validation: a real `kind`-native equivalent of `kafka-ha-demo.sh`

Reaching "pods show `Running`" was explicitly not treated as sufficient —
the validation bar set before building was a real kill test under real
continuous traffic, the same standard every other layer's HA pass in this
project was held to:

1. **Functional check**: full login → create meter → create reading →
   poll until the async Kafka pipeline lands it in Postgres, confirmed via
   `GET`.
2. **Kill test**: started continuous real traffic (`POST /readings` every
   0.4s) through Traefik. `kubectl delete pod kafka-1` mid-stream. Polled
   (not a fixed sleep) for its return.

**Results, confirmed live, not assumed:**

- `kafka-1` returned in **19s** with the same pod name — a genuinely new
  pod (new IP, new container), reusing the *identity* — the actual
  `StatefulSet` guarantee in action, not just asserted.
- **80/80 requests succeeded, zero failures**, across the entire
  kill-and-recovery window.
- All 81 total readings (80 during the test + 1 from the earlier
  functional check) confirmed landed in Postgres via a direct row count —
  not just trusted from HTTP `201`s.
- Full ISR (`0,1,2`) restored on every partition after recovery.

## Live re-verification (2026-09-08): design survives a real stop/start cycle, not just a continuously-running cluster

The cluster from the 2026-09-06 build had been sitting up, untouched, for two
days. Before committing this doc, re-ran the kill test against it live rather
than just re-narrating last week's session — the point being to confirm the
design still holds after a real stop/start cycle (the cluster had just gone
through a cold-start dependency race on its own restart, `api` settling to
1/1 and `local-path-provisioner` self-recovering, both as expected and
unrelated to Kafka), not only while continuously running.

**Results**: functional check landed clean; 27/27 traffic requests during a
`kubectl delete pod kafka-1` kill window succeeded (0 failures); the API-
visible reading count matched exactly (28 = 1 functional-check + 27 traffic);
full ISR (`0,1,2`) restored on every partition afterward. Same outcome as
2026-09-06 — zero request failures, correct data landed, full recovery — so
the design's own core claim (the app is unaffected by a single broker's
identity-preserving restart) holds on a second, independent run, not just the
original build session.

**A real measurement bug, caught rather than reported past**: the first
recovery-time check (`kubectl get pod kafka-1` polling for `Running`+`Ready`)
reported an implausible "0s" — a live instance of this project's own
standing lesson (a readiness check trusting a stale/coarse signal instead of
the actual condition it's meant to represent, `docs/testing-strategy.md`).
The old pod can still briefly report `Ready: true` during its own graceful
termination window, so a phase/ready check alone can't distinguish "the old
pod, still winding down" from "a genuinely new pod." Rebuilt the check
keyed off the pod's UID actually changing first, then confirming
`Running`+`Ready` on that new UID specifically — the same "check the actual
identity, not just a status field" discipline already applied to Kafka's own
pod-identity check in the original 2026-09-06 validation. Corrected number:
**~2.44s** from delete to `Running`+`Ready` on the new UID (new pod object
first observed at ~1.56s). This is faster than 2026-09-06's 19s, plausibly
because the container image was already cached and no cold pull was needed
either time, or because less broker state needed to be recovered on a
quieter cluster — not chased further, since the design's actual claim
(identity-preserving recovery, zero client impact) doesn't depend on the
absolute number matching between runs, only on it being real and bounded.
ISR confirmed fully restored (`0,1,2` on every partition) after this second
kill too.

**Incidental finding while cleaning up test data, not chased further**:
`DELETE /meters/{id}` returned `503` on a meter that still had readings
attached, rather than a clearer `409`/`400` conflict response. Worth a
look — `resilience-scope.md`'s `GlobalExceptionHandler` fix broadly catches
`DataAccessException` (mapped to `503`, for the Postgres-outage
misdiagnosis it was built to fix), and a foreign-key constraint violation
on delete is a `DataIntegrityViolationException`, a `DataAccessException`
subtype — plausibly now caught by that same broad handler and misreported
as "dependency unavailable" instead of "conflict," the mirror-image of the
bug that fix was built to close. Not confirmed or fixed here — flagged for
a follow-up look, out of scope for this doc.

## Deliverables from this pass

- `k8s/kafka.yaml` — `StatefulSet` (`kafka-0/1/2`) + headless Service.
- `k8s/configmap.yaml` — bootstrap-servers updated to all 3 pods; Redis
  property names corrected.
- `k8s/api.yaml` — `SPRING_PROFILES_ACTIVE: test` (Redis stopgap).
- `k8s/deploy.sh` — rollout check updated to `statefulset/kafka` (a
  `Deployment`-shaped check doesn't apply to this resource kind).
- `k8s/README.md` — new Redis entry in "Deliberate simplifications."

## Explicitly deferred / out of scope for this doc

- **k8s Redis Sentinel HA** — named above, tracked in `ha-scope.md`, not
  designed here.
- **Persistent storage for Kafka in `kind`** — unchanged from the original
  first-slice decision (ephemeral, no PVCs); not reopened by this pass.
- **Cloud Kafka topology** — `cloud-deployment-scope.md` already commits to
  self-hosting Kafka identically across AWS/GCP/Azure via each cloud's
  managed Kubernetes. This doc's `StatefulSet`/headless-Service design is
  exactly the artifact that gets reused there — the same manifests running
  on `kind`, EKS, and GKE alike, per that doc's own framing. Confirming
  that reuse (not redesigning it) is in scope once cloud work actually
  starts.
