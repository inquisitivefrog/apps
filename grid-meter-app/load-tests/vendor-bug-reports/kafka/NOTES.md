# Kafka — unclean leader election despite `unclean.leader.election.enable=false`

**Authoritative narrative and analysis**: `docs/testing-strategy-ha-supplement.md`
(Finding 2). This file is an index into `runs/` below, not a duplicate of
that analysis — read the doc for the actual theory and evidence chain.

**Filing status (2026-08-29)**: JIRA account requested, pending approval.
Not yet filed. Evidence-gathering continuing in the meantime.

## Environment (as of 2026-08-29, when all 4 runs below were captured)

| Component | Version |
|---|---|
| Kafka | 4.3.1 (`apache/kafka` image, KRaft mode) |
| Docker Client/Server (Desktop) | 29.7.2 |
| Docker Compose | 5.4.0 |
| Host OS | macOS 26.5.2, arm64 (Apple Silicon) |

`docker-compose.kafka-debug.yml` in this directory is a **frozen snapshot**
of the debug overlay used to capture runs 2, 3, and 4 below (TRACE-level
`org.apache.kafka.controller`/`org.apache.kafka.metadata`/`state.change.logger`
logging + JMX). It's a point-in-time copy, not a symlink — if the live
`docker-compose.kafka-debug.yml` at the repo root changes meaningfully later,
re-copy it here (or add a dated second copy) rather than assuming this one
still matches; don't let this go stale silently.

**Current working theory**: broker-fencing-triggered immediate promotion
from the Eligible Leader Replicas (ELR / KIP-966) set is a separate code
path from the periodic `electUnclean` task, isn't gated by
`unclean.leader.election.enable`, and logs at plain `DEBUG` with no
`UNCLEAN` label — making it invisible to log-based monitoring that only
watches for the labeled path. **Confirmed via three independent runs**
(runs 2, 3, and 4 below) — meets this project's 3-iteration bar for a
correctness/behavioral finding; considered proven, not merely reproducible.

## Runs

| Run | Date | Scenario | Verdict | Notes |
|---|---|---|---|---|
| [`20260828-194241-dynamic-override-run1`](runs/20260828-194241-dynamic-override-run1/) | 2026-08-28 | Dynamic topic-level `unclean.leader.election.enable=false` override; stop both followers, write via `acks=1`, stop leader, restart followers only | **Unsafe** — broker 3 (data-less) elected leader for partition 0 while broker 2 (true holder) still down | No TRACE debug logging active yet — external evidence only (script transcript + before/after snapshots) |
| [`20260829-192300-dynamic-override-run2`](runs/20260829-192300-dynamic-override-run2/) | 2026-08-29 | Same scenario, TRACE debug overlay active | **Unsafe** — broker 3 elected for partition 0 while broker 2 (true holder) confirmed fenced at the same instant via `controller.log` | First run with full internal confirmation: `BrokerRegistrationChangeRecord(brokerId=2, fenced=1)` and the unsafe promotion share the same timestamp; zero `UNCLEAN partition change` label anywhere in the log |
| [`20260829-193048-dynamic-override-run3`](runs/20260829-193048-dynamic-override-run3/) | 2026-08-29 | Same scenario, different broker/partition roles (leader=broker 1, promoted=broker 2) | **Unsafe** — same mechanism confirmed independently: broker 1 fenced, broker 2 promoted from `elr` in the same instant, plain `DEBUG`, no `UNCLEAN` label | Second internally-confirmed run — this is what elevated the finding from "reproducible" to "mechanism confirmed twice" |
| [`20260829-195450-dynamic-override`](runs/20260829-195450-dynamic-override/) | 2026-08-29 | Same scenario, leader=broker 2, promoted=broker 1 | **Unsafe** — identical mechanism a third time: broker 2 fenced, broker 1 promoted from `elr` 16ms later, plain `DEBUG`, zero `UNCLEAN` occurrences anywhere in the log | **Third independent confirmation — meets this project's 3-iteration bar for a correctness/behavioral finding. Path 2 mechanism is now considered proven, not merely reproducible.** |

Note: an earlier run (superseded, not preserved separately) captured the
*safe* outcome — the true leader correctly restored via ELR after the chaos
window closed, logged as `INFO ... UNCLEAN partition change` (the labeled,
correctly-gated path). That contrast — labeled-and-safe vs.
unlabeled-and-unsafe — is what distinguishes the two code paths described
above. See `docs/testing-strategy-ha-supplement.md` for the full account.

## Reproducing

`load-tests/kafka-unclean-election-dynamic-override.sh` runs the scenario
end to end and saves its own evidence into a new `runs/<timestamp>-*/`
directory here automatically. Bring up the TRACE debug overlay first for
full internal evidence:

```
docker compose -f docker-compose.yml -f docker-compose.kafka-debug.yml up -d kafka-1 kafka-2 kafka-3
docker compose restart api   # reconciles the readings topic back to 3 partitions
load-tests/kafka-unclean-election-dynamic-override.sh
```

`load-tests/kafka-debug-snapshot.sh [label]` captures a standalone
point-in-time diagnostic (config, topic state, active controller, JMX
counters) into `runs/` as a single timestamped file — useful for
before/after bracketing around a run.
