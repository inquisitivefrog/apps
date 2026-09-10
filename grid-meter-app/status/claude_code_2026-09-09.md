# grid-meter-app — Status: 2026-09-09 (Claude Code)

Resumed after an interruption from earlier the same day: the user had been
bouncing the `kind` cluster with new k8s config files from `k8s/` when
toggling VPN disrupted Docker Desktop access, forcing a laptop reboot.
Picked up from that point — recreated the `kind` cluster, validated the
already-on-disk (uncommitted, from before the reboot) k8s Redis Sentinel
port, and built out the actual chaos-test validation for it.

## Done

- **Full CLAUDE.md/docs/status/ review**, per user request at session
  start — read every file in `docs/` and `status/` in full (large files
  read in chunks) to catch up on current project state before doing any
  work.
- **Recovered from the VPN/reboot interruption**: confirmed Docker
  Desktop healthy again, found the `kind` cluster fully gone (wiped by
  the reboot) and the Compose stack down, but the k8s Redis Sentinel work
  itself intact and uncommitted on disk — a complete, coherent port
  (`k8s/redis.yaml` + new `k8s/sentinel.yaml`, both StatefulSets +
  headless Services mirroring `kafka.yaml`'s own migration;
  `configmap.yaml`/`api.yaml` switched to Sentinel-aware env vars;
  `deploy.sh` updated; `scripts/redis-entrypoint.sh` parameterized for
  k8s's headless DNS names).
- **Recreated the `kind` cluster and ran a full `./k8s/deploy.sh`**: clean
  rollout, all StatefulSets 3/3. `api` pods showed a benign, already-known
  Kafka-DNS cold-start race (self-healed via kubelet backoff, unrelated to
  the new Redis work).
- **Full functional validation through real HTTP traffic**: login → create
  meter → ingest reading → confirmed it landed via the async Kafka path →
  confirmed the Redis cache key exists specifically on the pod Sentinel
  reports as primary, proving the app's Sentinel-aware client is genuinely
  discovery-based.
- **Real kill test** (`kubectl delete pod redis-0` under continuous
  traffic): 50/50 requests succeeded, zero failures, correct same-identity
  pod recovery. The script's own printed recovery time ("1033s") was
  bogus — cross-checked against the pod's real `creationTimestamp` and
  confirmed the actual recreation took under a minute. Root cause:
  the laptop almost certainly went to sleep during the backgrounded
  script's poll loop, and `date +%s` correctly reflects real elapsed
  wall-clock time across a suspend, inflating the measured delta. Not a
  Redis/Sentinel issue — a laptop-sleep artifact.
- **Per explicit Claude Chat pushback, re-ran `docs/redis-ha-scope.md`'s
  own Stage 4 regression against Compose before trusting the k8s port** —
  it came back `SPLIT-BRAIN: YES`, a real, reproducible bug in the shared
  `scripts/redis-entrypoint.sh`, not a flake. Root-caused and fixed three
  distinct issues, all confirmed via live probing rather than guessed:
  1. `SENTINEL get-master-addr-by-name` can return the OLD master's
     address for several seconds after a new master is already promoted,
     until the entire failover completes — fixed by checking `SENTINEL
     master`'s `flags` for `failover_in_progress` before trusting the
     address.
  2. A node promoted via failover is known to Sentinel only by raw IP
     (no `replica-announce-ip` configured), never a hostname, so it could
     never again recognize itself as master on a later restart — fixed by
     also matching the node's own resolved IP, not just its hostname.
  3. A narrower race in the window right after a kill but before Sentinel
     even starts reacting shows `flags=s_down,master` (no
     `failover_in_progress` yet) — fixed by requiring an exactly-clean
     `master` flags value rather than denylisting specific unhealthy
     combinations.
  - The stricter flags check had a real cost: a genuinely fresh,
    simultaneous bootstrap under real resource contention (a concurrent
    `kind` cluster sharing the same Docker Desktop VM) could exhaust the
    original 30-attempt budget without ever settling. Widened to 60
    attempts, with the Stage 4 test script's own setup-wait bound widened
    to match (30s → 90s).
- **9 Compose Stage 4 runs across the fix's three iterations**: the
  original finding, 3 clean-but-incomplete runs under fix 1 only, one
  run under fix 1+2 that was clean by the write-acceptance metric but
  actually masked by a different safety net (revealing Bug 3), 2 clean
  runs under the full fix, one setup-timeout abort (closed by widening
  the budget), and 3 more clean runs after widening.
- **Rebuilt the k8s kill test with a real split-brain probe** (the
  original lacked one — it only checked request success and pod-UID
  change) and ran it under `caffeinate -i` to keep the timing measurement
  itself trustworthy this time: RTO 7s, pod recovery 7s, `SPLIT-BRAIN:
  NO` — protected further by applying `min-replicas-to-write` uniformly
  across all 3 k8s pods (a deliberate deviation from Compose, where only
  the original primary declares it).
- **Wrote `docs/k8s-redis-ha-scope.md`**, mirroring
  `docs/k8s-kafka-ha-scope.md`'s structure: design rationale, the
  entrypoint's per-pod parameterization (Downward API, ConfigMap
  generated at deploy time), the three bugs with full mechanism detail,
  and both validation passes with real numbers.
- **Added a new `docs/testing-strategy.md` lesson**: a laptop system-sleep
  gap during a backgrounded poll loop can inflate a `date +%s`-bracketed
  timing measurement by the full suspended duration — a distinct failure
  shape from the doc's existing readiness-check lessons, since the
  corruption happens between poll iterations, not within a stale signal.
- **Updated `k8s/README.md`'s "Deliberate simplifications"** (the old
  single-instance-Redis stopgap note was stale) and `docs/ha-scope.md`'s
  "Revisit triggers" entry (marked the k8s Redis Sentinel follow-up done).
- **Committed and pushed** as two commits: `ef8a2e7` (k8s manifests +
  entrypoint fixes + evidence transcripts) and `08d244b` (docs). Both on
  `origin/main`.

## Open / carried to 2026-09-10

- Claude Chat had not yet reviewed the finished work at end of day —
  follow-up questions (is Bug 1 new or pre-existing, single-Sentinel-lag
  or a real quorum/cross-Sentinel race) arrived and were resolved the
  next day; see `status/claude_code_2026-09-10.md`.
- The `kind` cluster and the Compose Redis/Sentinel tier were both left
  up at end of day.

## Next

- Await Claude Chat's review of `docs/k8s-redis-ha-scope.md` and the
  pushed fixes.
