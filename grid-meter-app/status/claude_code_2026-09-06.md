# Session status — 2026-09-06 (Claude Code)

## Done

- **k8s Kafka HA follow-up slice: proposed, approved, built, and
  validated live end-to-end — the full arc in one session.**
  - **Phase 1 (investigate + propose, no manifests written yet)**:
    confirmed live against the actual `k8s/kafka.yaml` that it was
    still the single-broker `Deployment` `k8s-terraform-decisions-
    2026-08-19.md` described (no drift), and that `configmap.yaml`'s
    `SPRING_KAFKA_BOOTSTRAP_SERVERS: kafka:9092` was the one value that
    would need to change. Proposed a `StatefulSet` + headless Service
    design, explaining the *why* at each step per the user's explicit
    framing ("part of the value here is genuinely learning kind/
    StatefulSet mechanics"): why a StatefulSet's ordinal pod naming +
    per-pod DNS is what KRaft's quorum voter list actually needs (a
    Deployment's random pod names and single load-balancing Service
    structurally can't provide it); which derived values need a tiny
    startup-script wrapper (`KAFKA_NODE_ID` — confirmed live via
    `docker inspect`/`configure` that the image has no
    Kubernetes/hostname awareness of its own, so extracting an ordinal
    needs shell) versus which are pure manifest templating
    (`KAFKA_ADVERTISED_LISTENERS` via Kubernetes' own `$(VAR)` env
    interpolation; the shared `KAFKA_CONTROLLER_QUORUM_VOTERS` list,
    since replica count and pod names are fixed and known upfront).
    Proposed 0-indexed node IDs (simpler than matching Compose's 1/2/3)
    and flagged it as a real, if minor, decision rather than assuming
    it. Approved as proposed.
  - **Build**: `k8s/kafka.yaml` → `StatefulSet` (`kafka-0/1/2`) +
    headless Service; `configmap.yaml`'s bootstrap-servers → all three
    pods by headless DNS name, matching Compose's proven
    `kafka-1,kafka-2,kafka-3` shape exactly; `deploy.sh`'s rollout
    check → `statefulset/kafka` (a `Deployment`-shaped check doesn't
    apply to that resource kind).
  - **Real friction along the way — two pre-existing bugs, both
    unrelated to Kafka, that blocked the app from starting in k8s at
    all**: (1) k8s's Redis was never updated after the app's Redis
    Sentinel cutover landed in the code (`application.yml` activates
    Sentinel for every profile except `test`; k8s's `redis.yaml` is a
    single plain Deployment, no Sentinel — the exact "app-vs-
    infrastructure, never actually cut over" shape CLAUDE.md already
    names as a standing risk, just found on Redis this time); (2)
    `SPRING_REDIS_HOST`/`PORT` in the ConfigMap were the pre-Spring-
    Boot-3 property names, silently binding to nothing since Boot 3+
    moved this under `spring.data.redis.*` and no explicit `${...}`
    placeholder exists for host/port the way Sentinel's keys have.
    Neither had ever been exercised before, since Compose always runs
    in Sentinel mode. Fixed both — `SPRING_PROFILES_ACTIVE: test` and
    renamed to `SPRING_DATA_REDIS_HOST`/`PORT` — and caught my own
    mistake along the way: assumed the profile fix had taken effect
    from a clean-looking pod's logs, then verified directly with
    `kubectl exec ... env | grep` and found it hadn't actually been
    wired into `api.yaml` at all yet. Fixed that too.
  - **Validation, live not reviewed**: full login → create meter →
    create reading → poll until the async Kafka pipeline lands it in
    Postgres, confirmed via `GET`. Then the actual kill test asked
    for: started continuous real traffic (`POST /readings` every
    0.4s) through Traefik, `kubectl delete pod kafka-1` mid-stream,
    polled (not a fixed sleep) for its return. **Confirmed live**:
    `kafka-1` came back in 19s with the same name (a genuinely new
    pod — new IP, new container — reused identity, the actual
    StatefulSet guarantee in action, not just asserted), and **80/80
    requests succeeded with zero failures** across the entire kill-
    and-recovery window. Confirmed all 81 total readings (80 + 1
    earlier) actually landed in Postgres, not just that HTTP reported
    success. Cluster's own topic state after recovery: full ISR
    (`0,1,2`) on every partition.
  - **Cleanup round, per explicit follow-up request**: reworded the
    `SPRING_PROFILES_ACTIVE: test` comment — now that it's properly
    wired in and live-verified working, "stopgap, not a real fix"
    language was stale and risked reading as an unresolved hack to a
    future reader; reworded as the deliberate, working setting it now
    is. `k8s/README.md`'s "Deliberate simplifications" section gained
    a Redis entry alongside the existing ephemeral-storage one,
    matching this project's standing convention of naming
    simplifications explicitly rather than leaving them as silent
    gaps. `docs/ha-scope.md`'s "Revisit triggers" section gained a
    new, explicitly unscoped entry for a k8s Redis Sentinel HA
    follow-up (mirroring today's Kafka work) — recorded there
    specifically because the Kafka slice itself sat as an easy-to-
    lose "revisit later" item for weeks before actually getting
    picked up; this is meant to keep the Redis one from disappearing
    the same way.

## Committed and pushed

Three commits, `9330a1a..bbc08b4`:
1. `139689c` — the StatefulSet migration + both Redis bug fixes +
   live kill-test validation.
2. `bbc08b4` — the wording/documentation cleanup round (stopgap
   language reworded, README simplification entry, `ha-scope.md`
   follow-up tracking).

## Open / Next

- **A genuine k8s Redis Sentinel HA follow-up is now durably tracked**
  in `docs/ha-scope.md`'s "Revisit triggers" section — explicitly not
  scoped or designed yet, just named so it doesn't silently disappear.
  Mirrors today's Kafka work: `k8s/redis.yaml` would need the same
  StatefulSet + headless Service treatment, plus removing the
  `SPRING_PROFILES_ACTIVE: test` workaround once real Sentinels exist
  to discover.
- The `kind` cluster from today's validation was left up mid-session
  for inspection; status as of this file's writing not reconfirmed —
  check `kind get clusters` / `kubectl get pods` before assuming it's
  still there, and `./k8s/teardown.sh` to tear down when done with it.
- Nothing else outstanding from today's work — both the build and the
  cleanup round are fully committed and pushed.
