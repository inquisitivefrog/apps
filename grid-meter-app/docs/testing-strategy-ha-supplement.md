# grid-meter-app — Testing strategy supplement: multi-node HA & alert taxonomy

Supplementary notes on testing and alerting concerns raised by the move
toward multi-node data-tier redundancy (see `docs/ha-scope.md` for the
scope decision itself: Kafka multi-broker this pass, Redis/Postgres
deferred). Collected here as a follow-on to `testing-strategy.md` rather
than expanding that file indefinitely — same pattern `identity.md` already
uses for auth follow-on questions.

## Status update (2026-08-28, later): root cause identified — a second, unlabeled, ungated promotion code path, not a race

**This supersedes the "race condition" framing above.** What looked like
non-determinism (Run 1 unsafe, Run 2 safe, same config) turned out to be
two structurally different promotion mechanisms in KRaft's controller,
one of which was never being checked for:

- **Path 1 — the periodic `electUnclean` task.** Logs an `INFO ...
  UNCLEAN partition change` line when it promotes a replica from the
  `elr` (Eligible Leader Replicas / KIP-966) set. This is the labeled,
  expected unclean-election path, and it's the one Run 2's earlier
  analysis correctly confirmed behaved safely (elected the true data
  holder, logged with the `UNCLEAN` label). Confirmed via direct log
  search that this task **never fired** during the Run 3 reproduction
  below — it was only seen being cancelled at controller startup,
  unrelated to the actual promotion.
- **Path 2 — broker-fencing-triggered immediate reassignment
  (newly identified).** When a broker is fenced
  (`BrokerRegistrationChangeRecord(..., fenced=1)`), `ReplicationControlManager`
  immediately promotes a replacement leader from the `elr` set in the
  same instant — logged at plain `DEBUG`, with **no `UNCLEAN` label at
  all**, indistinguishable in a casual log read from an ordinary safe
  ISR transition.

**Reproduced and captured under full TRACE logging (Run 3).** The exact
causal chain, from the TRACE log, both lines sharing the same timestamp
across all 3 brokers:

```
02:23:38,907  BrokerRegistrationChangeRecord(brokerId=2, ..., fenced=1)
02:23:38,907  isr: [2] -> [3], leader: 2 -> 3, leaderEpoch: 0 -> 1,
              elr: [3] -> [2], partitionEpoch: 2 -> 3
```

Broker 2 — the true leader and the only replica holding the acknowledged
write — was fenced. In the same instant, broker 3 — which had already
dropped out of ISR and held no copy of the write — was promoted to
leader, with broker 2 demoted into the `elr` set instead (broker 2 does
not reappear in ISR until two transitions later, confirming it was still
down at promotion time, not a stale log artifact). **This transition is
not gated by `unclean.leader.election.enable`, confirmed with a live,
verified dynamic override in place** — the config Path 1 presumably
respects has no effect on Path 2 at all.

**Why the earlier detection methodology ("grep for `UNCLEAN partition
change`") would have missed this entirely, and did on the first attempt
at this run**: Path 2's promotion has no `UNCLEAN` label. A grep-based
check would report "no unclean election events" for a run that actually
contains an unsafe promotion — a false negative, not merely an
incomplete signal. This was caught only because the absence of the
`UNCLEAN` label was treated as a reason to look closer, not as
confirmation of safety — the same broker-vs-holder cross-check
methodology from the previous update, applied one level deeper (checking
every `isr`/`leader`/`elr` transition, not just ones carrying a specific
log label).

**Sharper statement for the upstream bug report**: KRaft's controller
appears to have two independent replica-promotion-from-ELR code paths —
one via the periodic `electUnclean` task (labeled, apparently gated by
`unclean.leader.election.enable`) and a second via broker-fencing-triggered
immediate reassignment in `ReplicationControlManager` (unlabeled, and
not respecting `unclean.leader.election.enable` even under a confirmed
dynamic override). This is a precise, mechanistic claim — a specific code
path bypassing a specific config check — not a symptom report of
occasional unsafe elections.

**Evidence status, updated**: TRACE-level, internally-confirmed captures
now exist for **both** outcomes — Run 2 (safe, via Path 1) and Run 3
(unsafe, via Path 2) — stored alongside each other for direct comparison
in the bug report. This closes the evidence gap named in the prior
update.

## Status update (2026-08-28, earlier): `acks` gap found and fixed; initial investigation into the unclean-election finding

**Note: the root-cause investigation below was superseded within the same
day — see the "root cause identified" update above, which supersedes the
"race condition" framing that follows.** Retained for the historical
trail (two ruled-out tickets, the Run 1/Run 2 divergence that first
suggested non-determinism) since that reasoning is what led to the
methodology that ultimately found the real mechanism.

Running the Failover/RTO test's own stated verification step for real —
"confirm `acks=all` and a replication factor > 1 are actually configured,
not just present in a config file" — surfaced a real, previously
unverified gap, plus a second, more serious finding. That second finding
is real and reproducible, but non-deterministic — the same scenario
against the same config produced a safe outcome once and an unsafe
outcome once. The specific upstream ticket first cited as its explanation
was incorrect and has been corrected below; a second candidate ticket has
also since been ruled out. This now looks like a genuine, not-yet-filed
upstream Kafka bug, and evidence-gathering toward filing one is actively
in progress.

**Finding 1 — `acks` was undeclared, defaulting to `1` (fixed).**
`application.yml`'s Kafka producer config declared `max.block.ms` and
`delivery.timeout.ms` explicitly but never `acks`, so it silently
inherited the raw Kafka client default of `1` (leader-only
acknowledgment). This matters concretely: `min.insync.replicas=2`
(already configured on the topic per `docs/ha-scope.md`) is a
broker-side check that only gets *enforced* when the producer uses
`acks=all` — with `acks=1`, a leader can acknowledge a write, then die
before replicating it to the other two brokers, and it's gone despite
`replication-factor=3`. Confirmed empirically before fixing (not
assumed): with both followers stopped, a write to the sole remaining
leader still returned `201`, proving a write can be acknowledged while
only 1 of 3 replicas holds it. **Fixed**: `acks: all` declared explicitly
in `application.yml`, re-verified against the same reproduction — no
longer acknowledges on a single replica.

**Finding 2 — real, reproducible unclean leader election on live Kafka
4.3.1, despite `unclean.leader.election.enable` correctly evaluating to
`false` — now believed to be a race condition, neither previously-cited
JIRA ticket applies, evidence-gathering in progress toward filing a new
bug.** While reproducing Finding 1, killing the leader after both
followers had been stopped and restarted (neither having received the
write) resulted in one of the data-less followers being elected leader
for that partition — real unclean leader election, which
`unclean.leader.election.enable=false` should have prevented. The write
ultimately survived once the correct replica rejoined, but only because
no conflicting write landed on the data-less leader in the interim — a
fragile, timing-dependent survival, not a structural guarantee. **The
reproduction itself is solid**: run against live Kafka 4.3.1 (confirmed
via the pinned `docker-compose.yml` image and live `kafka-topics.sh
--version`), using a script that dynamically targets the actual
partition leader rather than a fixed broker.

**Correction (2026-08-28): an earlier version of this entry cited
[KAFKA-19148](https://issues.apache.org/jira/browse/KAFKA-19148) as the
explanation. That citation was wrong and is retracted.** KAFKA-19148 was
resolved in Kafka **4.1.0** — a version older than the 4.3.1 this project
runs — and its actual mechanism is specific to an unclean leader election
racing a partition *reassignment* completing. This test never triggers a
reassignment at all, so the scenario doesn't match. The symptom
(`unclean.leader.election.enable=false` not being honored) was similar
enough to feel like a match without checking the fix version first, which
is exactly the kind of thing this project's own discipline elsewhere
(verify, don't assume) exists to catch.

**Update (2026-08-28): [KAFKA-19552](https://issues.apache.org/jira/browse/KAFKA-19552)
also ruled out — wrong polarity, not just an uncertain fit.** 19552
describes unclean election *failing to trigger when it's wanted*
(a static/dynamic config-precedence bug suppressing an intended unclean
election). This project's finding is the opposite: unclean election
*triggering when it shouldn't*. The two aren't the same bug wearing
different config values — they're inverse failure modes, so 19552 is
ruled out on its own terms, not merely deprioritized for the earlier
structural-mismatch reasons (separate broker/controller processes vs.
this project's combined nodes, which still stands as a secondary reason
even if the polarity issue weren't disqualifying on its own).

**Current working theory: a race condition in Kafka's Eligible Leader
Replicas (ELR / KIP-966) decision path, not a simple "config is ignored"
bug.** The repro was run twice against an explicit, confirmed-live
*dynamic* topic-config override for `unclean.leader.election.enable`
(not merely an unset default — closing off "nobody explicitly configured
it" as an explanation on its own):

- **Run 1**: reproduced the bug — a data-less broker (broker 3) was
  elected leader despite the override being live and confirmed.
- **Run 2** (with a TRACE-level debug logging overlay active on all 3
  brokers' `controller.log`/`state-change.log`): did **not** reproduce
  the unsafe outcome. **Correction, refined after the internal-log
  analysis below**: this was initially described as the partitions
  "going leaderless," based on the external admin-API view; TRACE-level
  analysis of the controller's actual internal decisions (see below)
  showed this was imprecise — broker 3, the true data-holding former
  leader, was correctly elected via the `lastKnownElr` fallback path,
  not left leaderless. Either way, the outcome was safe: no data-less
  broker was elected.

**Same config, same scenario, two different outcomes — one unsafe, one
safe.** That divergence is the important finding: it points toward a
timing-dependent race in the ELR decision path rather than a
straightforward misconfiguration or a deterministic logic bug, which is
a materially stronger and more specific thing to hand upstream than a
flat "unclean election happened" repro would have been.

**Evidence status (superseded — see "Upstream bug report" below): full
TRACE-level `controller.log`/`state-change.log` for all 3 brokers now
exists for both outcomes.** This paragraph originally noted only Run 2
(the safe outcome) had been captured, with the actual unsafe mechanism
still uncaptured. That gap is closed: Run 3 (below, also unsafe, via Path
2) was captured under full tracing and its exact causal log lines
analyzed. Evidence lives in `load-tests/vendor-bug-reports/kafka/` (moved
from the original `load-tests/kafka-bug-report/` once the same evidence
archive pattern was generalized to cover other suspect technologies —
Redis/Sentinel, PostgreSQL clustering — see
`docs/vendor-bug-report-process.md` for the full layout and how to resume
this investigation after time away).

**Filing status**: a JIRA account is pending approval; filing itself is
blocked on that, but evidence-gathering does not need to wait on it and
is continuing.

**Root-cause status: actively being chased, not parked.** This
supersedes the earlier "parked, not abandoned" framing from when 19552
still looked like a plausible lead — the polarity mismatch closes that
lead entirely rather than leaving it merely unconfirmed, and the Run
1/Run 2 divergence under tracing is specific enough evidence to be worth
pursuing toward an actual upstream bug report rather than stopping at
"reproducible, cause unknown." Next concrete step: re-run the
dynamic-override experiment several more times with the TRACE overlay
active, aiming to catch a reproduction of the *unsafe* outcome (Run 1's
behavior) with full tracing on, which is the log this project doesn't
yet have and needs for a credible bug report.

**Confirmed, unrelated to either ticket**: `docker-compose.yml` never
declared `unclean.leader.election.enable` at all — `grep` returns
nothing, and `kafka-configs.sh --describe --all` confirms its active
value comes from Kafka's own `DEFAULT_CONFIG` synonym tier, not a static
override from this project. That means "it's false" was true by
accident, not by declaration — the same undeclared-load-bearing-default
pattern already found and fixed for the HikariCP timeout, `max.block.ms`,
`delivery.timeout.ms`, and `acks`. **Fixed**: declared explicitly as
`unclean.leader.election.enable=false` in `docker-compose.yml`. This
doesn't change behavior on its own (the default already matched), only
removes the accident — and, as Run 1 above shows, an explicit dynamic
override doesn't prevent the race either, so this fix closes the
"undeclared default" gap specifically without being a claim that it
closes the underlying bug.

**Clarification (2026-08-28): this declaration is good practice, but it
does not test KAFKA-19552's actual mechanism, and shouldn't be read as
having done so.** 19552's suggested workaround is to set the value on
*controller* properties specifically, because its bug is a
broker-vs-controller config precedence mismatch — it only exists when
brokers and controllers are separate processes with separate static
config files that can diverge from each other. This project's cluster
runs `KAFKA_PROCESS_ROLES: broker,controller` — combined roles, one
process, one config, per node. There is no separate "controller
properties" file here for a broker-side value to diverge from, which is
the same structural reason (independent of the polarity mismatch) this
doc already used to rule 19552 out. Declaring the value explicitly is
worth doing on its own merits (removing an undeclared load-bearing
default), but it isn't a test of 19552's mechanism, because that
mechanism has nothing to act on in this topology.

**Confirmed at the controller's actual internal decision level, not just
the external admin-API view (2026-08-28).** A fair question was raised:
does `kafka-configs.sh --describe` only report what the admin API
*claims* the effective config is, without proving the controller's
election-decision code reads that same value at the moment it actually
decides? Checked directly against Run 2's TRACE logs rather than left as
an open assumption: every `UNCLEAN partition change` line across all 3
brokers' logs and all 3 `readings` partitions in Run 2 (9 occurrences
total) elected broker 3 — which was the recorded `lastKnownElr`, the
true, data-holding former leader, rejoining right after the script's
"Restoring kafka-3" step. No data-less broker was ever elected in Run 2.
This confirms TRACE-level logging does expose the controller's actual
internal reasoning, not just an external, possibly-stale admin view —
and that Run 2 really was safe internally, not merely safe as observed
from outside.

**Important nuance surfaced by this check, worth stating precisely for
any future bug report**: Kafka's controller logs the label `UNCLEAN
partition change` for *any* election that goes through the
`lastKnownElr` fallback path — **regardless of whether the elected
replica is actually the correct, fully-caught-up one (as in Run 2) or a
genuinely stale, data-less one (as Run 1 appears to have been).**
"UNCLEAN" in this log line means "elected outside the normal live-ISR
path," not "data was lost." Treating the two as synonymous would be an
imprecise claim to put in front of the Kafka team, and this doc
deliberately avoids that conflation from here on.

**Sharper test methodology proposed here, later found insufficient on its
own**: the original plan was to grep for `UNCLEAN partition change`, then
check whether the elected broker actually held the acknowledged write.
**This was tried and failed to catch the actual mechanism** — see the
"root cause identified" update above. Path 2 (broker-fencing-triggered
immediate reassignment) produces no `UNCLEAN` label at all, so a
grep-based check reports a false negative for a run that contains a real
unsafe promotion. The corrected methodology is to check every
`isr`/`leader`/`elr` transition line, not just ones carrying the
`UNCLEAN` label — see the dual-path finding above for the full
reasoning and the log evidence that exposed the gap in this note's
original approach.

**Test infrastructure note**: a second, test-specific `docker-compose.yml`
variant (`docker-compose.kafka-debug.yml` at the repo root, used as a
Compose override: `-f docker-compose.yml -f docker-compose.kafka-debug.yml`)
was created for this investigation to isolate the debug-logging overlay
and repeated-teardown cycles from the project's main development compose
stack. Its evidence and a frozen copy of that compose file live in
`load-tests/vendor-bug-reports/kafka/` — see `docs/vendor-bug-report-process.md`
for the full evidence-archive layout, which also covers Redis/Sentinel and
PostgreSQL clustering once their own HA testing starts.

### Sentinel test: `uncleanPromotionViaBrokerFencing_ungatedByConfig`

To avoid this becoming a rediscovered surprise months from now, this is
tracked with a **sentinel test** — a test written with its assertion
deliberately inverted, asserting the *known-broken* behavior rather than
the *correct* behavior, so it fails loudly (not silently) the day the
underlying behavior changes, rather than requiring anyone to remember to
go check this doc or a JIRA ticket periodically. **Renamed from
`uncleanElectionStillReproduces_rootCauseUnconfirmed`** now that the root
cause is confirmed (Path 2, broker-fencing-triggered immediate
reassignment) rather than an unconfirmed race — the name should describe
the actual mechanism now that it's known.

- **What it does**: reproduces the exact scenario that triggers Path 2
  (fence/kill the true leader while it's the sole holder of an
  acknowledged write, with the other two replicas already out of ISR),
  then checks the resulting `isr`/`leader`/`elr` transition line — **not**
  a grep for the `UNCLEAN` label, which Path 2 does not emit (see the
  dual-path finding above; an earlier version of this test plan relied on
  the label and would have produced a false negative).
- **What it asserts**: that the promoted leader is a broker that did
  **not** hold the acknowledged write — i.e., it currently **passes
  because the bug is present**. Includes an assertion-failure message
  pointing directly at this section, the exact log-line pattern to check
  (`isr: [X] -> [Y]` where Y did not hold the write), the Kafka version
  tested against (4.3.1), and the date this was last confirmed.
- **What a failure means**: if this test starts failing (the promoted
  leader always holds the write going forward), that's the trigger to
  re-run the full Failover/RTO test properly, check whether `acks: all`
  alone is now sufficient, update this doc with confirmation that Path 2
  has been fixed or gated upstream, and only then flip the test's
  assertion to the normal, correct-behavior direction.
- **Where it lives**: alongside the other HA chaos scenarios (e.g.
  `load-tests/kafka-ha-demo.sh`-adjacent), not in the fast/every-push
  test tiers — it kills/fences brokers and takes real wall-clock time,
  same reasoning already applied to the quorum-loss and rolling-
  maintenance scenarios below. **Confirmed (2026-08-29): Path 2 reproduced
  3 for 3** across independent runs once correctly triggered (fence the
  sole holder of an acknowledged write while the other replicas are
  already out of ISR) — meets this project's 3-iteration bar for a
  correctness/behavioral finding. The multiple-attempts design originally
  planned for a suspected timing race is confirmed unnecessary: this test
  can assert the unsafe outcome on a single attempt, not "at least one of
  several."

### Upstream bug report: mechanism confirmed, ready to file pending JIRA access

Distinct from the sentinel test above (which guards this project against
a silent behavior change), a genuine upstream Apache Kafka bug report is
ready to be written up in full, since neither existing ticket explains
the observed behavior and the actual mechanism is now understood:

- **TRACE-level `controller.log`/`state-change.log` for all 3 brokers,
  captured for both outcomes**: Run 2 (safe, via Path 1 — the periodic
  `electUnclean` task) and Run 3 (unsafe, via Path 2 — broker-fencing-
  triggered immediate reassignment). Both fully analyzed, including the
  exact causal log lines for Run 3 (see above).
- **Key distinction established across both analyses**: the `UNCLEAN
  partition change` log label is emitted by Path 1 only. Path 2's
  promotion is unlabeled, logged at plain `DEBUG`, and is not gated by
  `unclean.leader.election.enable` even under a confirmed live dynamic
  override. Any bug report needs to state this precisely — the config
  appears to work for one internal mechanism and not the other, which is
  a materially different and more specific claim than "unclean election
  sometimes happens."
- **Bug report shape**: two independent promotion-from-ELR code paths
  exist in KRaft's controller; Path 2 bypasses the config gate Path 1
  respects. Include the Run 2/Run 3 log excerpts side by side as direct
  evidence, plus the reproduction steps (fence the sole holder of an
  acknowledged write while the other replicas are already out of ISR).
- **Filing status**: blocked on JIRA account approval; the report itself
  can be drafted now, ready to file the moment access clears.

## Alert taxonomy: incident alerts vs. trend alerts

**Note (2026-08-27): superseded/extended by `docs/observability-taxonomy.md`**,
which organizes this split plus two further categories (notices, reports
& dashboards) surfaced by a broader "beyond incidents, what else is being
observed" discussion. This section's content is retained below since
nothing in it is wrong, just incomplete on its own now.

The 3 rules built during chaos testing (`API is down`, `High HTTP error
rate`, `Tomcat thread pool saturated`) are all the same *shape* of alert:
a threshold crossed for a sustained window, requiring someone to drop
what they're doing and respond right now. That shape has a name worth
making explicit and standard going forward:

- **Incident alerts** — threshold-crossing, page-worthy, sustained-window
  by design (the existing `>5% for 30s` pattern already guards against
  paging for a 5-second blip that self-heals). Answers: "is something
  broken right now that needs a human immediately." All 3 existing rules
  belong in this category.
- **Trend alerts** — capacity-planning signals, informational rather than
  page-worthy. Answers: "is something heading toward a problem, on a
  timescale that allows planning rather than firefighting." Structurally
  different from every incident alert built so far: those fire only after
  a threshold is already breached; a trend alert fires on a *slope*, days
  or weeks before any threshold would trip.
  - **Concrete example driving this category**: a one-writer/N-reader
    Postgres topology (the "star" configuration — appropriate here since
    this project's actual read/write mix is read-heavy) shifts all
    write-capacity planning onto the single writer node, since it's the
    one node that can't scale horizontally — readers absorb read load,
    but write throughput is bounded by whatever that one box can do until
    someone manually resizes it. The writer needs its own trend alert on
    CPU, active connections, and disk usage climbing over days-to-weeks,
    specifically to trigger a *planned* blue-green hardware swap before
    capacity exhaustion becomes an incident. This only becomes buildable
    once Postgres has a real writer/reader split (i.e., once the deferred
    Postgres HA scope in `docs/ha-scope.md` is picked up) — recorded here
    now so the shape of the alert isn't lost in the meantime.

**A third, related category worth designing at the same time:** once real
multi-node redundancy exists (starting with Kafka), a **failover event**
notification — "leader changed, no client-visible impact" — is neither an
incident (nothing broke) nor a trend (nothing is climbing toward a
future problem) but is still worth a record. Design this alongside trend
alerts rather than as an afterthought; it's informational-only, same as
trend alerts, but event-triggered rather than time-series-based.

**Action items** (tracked here):

1. ~~Relabel the existing 4 rules in `observability/alerting/rules.yml` as
   incident alerts~~ — **Done (2026-08-27)**: `alert_class: incident`
   added to each rule's `labels:` block, verified live via Grafana's
   provisioning API.
2. Design trend alerts as their own scoping task — needs the retention
   discussion below resolved first, since a trend alert is only as useful
   as the time-series window it can actually see. **Not started.**
3. Design the failover-event notification category alongside trend
   alerts, once Kafka multi-broker exists to generate real failover
   events to test against. Kafka multi-broker now exists (see below) —
   **still not started; no actual alert/notice exists yet for a Kafka
   leader change.**

## Retention gap: trend alerts need more than the dashboards currently keep

Trend alerts are only as good as the time-series window behind them.
Day-to-day dashboards answering "what's happening right now" are commonly
retained on a short window (7 days is a typical Prometheus default) — fine
for incident response, where recent history is all that matters, but
actively insufficient for capacity planning, which needs to see gradual
change over weeks or months to be useful at all. A 7-day retention window
that quietly discards the very trend a capacity-planning alert exists to
catch defeats the purpose before the alert is even built.

**Options, cheapest first:**

- **Raise local Prometheus's `--storage.tsdb.retention.time`** — a
  one-line config change, bounded by local disk, no new infrastructure.
  The right first step if disk budget allows a few weeks-to-months of
  retention; re-check actual on-disk size per day of retention before
  committing to a number. **Not done — no override found anywhere in the
  repo as of 2026-08-28.**
- **Downsampling** — keep high-resolution data for a short window (for
  incident alerts) and a lower-resolution rollup for a much longer window
  (for trend alerts), reducing storage cost per day of history retained.
  Prometheus itself doesn't do this natively; would need either a
  recording-rule-based rollup or a dedicated long-term-storage layer.
- **Long-term storage (Thanos, Cortex, or Mimir)** — the real answer for
  retention measured in months-to-years with proper downsampling, but a
  materially bigger lift: object storage, a separate query layer, and
  genuinely new infrastructure this project hasn't needed yet. Matches
  the same "don't inject infrastructure the project doesn't have a real
  target for" reasoning already applied to ruling Terraform out of scope
  — worth its own explicit scope decision, not an assumed default.

**Recommendation:** raise local retention first (cheap, no new
infrastructure) and treat long-term storage as a "revisit only if" item —
same framing already used for Terraform, TLS, and the Postgres HA
decision above — revisit only if retention needs genuinely exceed what
local disk can reasonably hold.

## Multi-node testing goals (Kafka first)

The single-instance chaos tests answered one question: does an alert fire
when the only instance of a layer dies. A real multi-broker Kafka cluster
makes a different, more specific set of questions testable, and these
are the tests this pass should add — not a repeat of the existing
single-instance chaos scenario against a bigger cluster.

**Status (2026-08-28): Kafka multi-broker (3-broker KRaft) is built and
largely tested; see below per-scenario.**

- **Failover / RTO test** — kill the current partition leader broker,
  measure actual time-to-new-leader, confirm producers/consumers resume
  automatically with no data loss (verify `acks=all` and a replication
  factor > 1 are actually configured, not just present in a config file).
  This is the test that validates real fault tolerance, not just
  replication existing on paper. **Status: done (2026-09-02), 3/3 valid
  runs — superseding an earlier, incomplete single-run write-up of this
  same fix. Its RTO-variance finding below was itself retested
  (2026-09-02) and substantially revised: the leading "controller
  failover" hypothesis was refuted, and most of the original variance
  turned out to be the test harness's own JVM-spawn overhead, not a
  Kafka-internal mechanism — see "RTO variance retest" below for the
  full account.** The original gap (`kafka-ha-demo.sh` Scenario 1 stopping
  `kafka-2` unconditionally regardless of whether it actually led any
  partition the test's traffic used, and never measuring real RTO — just
  assuming a fixed 5-second sleep was enough) is closed. With 3
  partitions spread across all 3 brokers, the old unconditional-kill
  approach risked silently testing nothing on any given run. Fixed
  properly: the script now determines which partition a run's traffic
  actually lands on (via an offset diff around a canary write), kills
  that partition's real current leader, and measures genuine RTO by
  polling concurrently with sending traffic.

  **Getting there required fixing 3 real bugs, not just retargeting the
  kill — each one worth recording on its own:**

  1. **The monitoring helper's own hardcoded query target.**
     `cluster_state()` hardcoded its query target to `kafka-1`; the
     first run that actually killed `kafka-1` itself had every poll
     during the outage silently query a dead container, producing a
     false "no leader elected" result that looked like a real Kafka
     failure but was actually the monitoring tool losing its own
     vantage point. Fixed by having the script dynamically pick a
     surviving broker to query rather than assume any specific one
     stays up.
  2. **Scenario 2's durability check was still querying the standalone
     `postgres` container** — retired earlier in the same session
     during the Postgres HA pass's own application-cutover work (see
     `docs/postgres-ha-scope.md`'s Stage 7). A shared-infrastructure
     retirement in one pass silently broke an unrelated verification
     step in another; see `docs/cross-project-lessons.md` for the
     general lesson this prompted about checking cross-pass references
     before retiring shared containers.
  3. **Fixing bug 2 by hardcoding the query to a specific `patroni-N`
     container would have reintroduced bug 1's exact mistake in a new
     location** — caught before landing, not after. Routed through
     Traefik's `:55432` entrypoint instead (built and verified during
     Postgres's own Stage 7, reused here rather than re-invented), which
     always reaches whichever node is actually primary. That fix
     surfaced one more real bug: the TCP connection through Traefik
     needs password auth (`md5` in `pg_hba.conf`), which the original
     local-socket connection never needed — fixed with `PGPASSWORD`,
     matching the pattern already used elsewhere in the Postgres test
     scripts. **Worth cross-referencing into `docs/postgres-ha-scope.md`
     directly** — this is a Postgres/Traefik connection-behavior fact,
     discovered incidentally in a Kafka test script rather than in
     Postgres's own pass.

  **Real RTO across all 3 valid runs**: 3.7s, 14.0s, and 15.5s. Zero
  HTTP-level impact in all 3 runs (20/20 requests succeeded in every
  run). **The variance itself is a real finding, not noise to average
  away — and sharper than it first looks: checked directly against the
  saved transcripts (not assumed), all 3 runs killed the same broker
  (`kafka-1`)**, not just "some" — each run's baseline happened to show
  `kafka-1` leading the partition the freshly-created test meter's key
  landed on. Two of the three runs (the 3.7s and 15.5s ones) hit the
  *same partition* too (partition 1), yet still produced a >4x RTO
  spread with the identical broker and partition both held constant.
  This rules out "different broker" or "different partition" as the
  explanation for the variance by construction, not merely as an
  unexamined possibility — whatever drives the spread has to be
  something else (controller/replica state at the moment of failure,
  timing relative to the periodic controller heartbeat, or similar),
  stated as an open question rather than a confirmed mechanism, since
  isolating the real cause would need dedicated instrumentation this
  stage didn't build. This is the first real, trustworthy
  time-to-new-leader number this test has ever produced; the original
  Scenario 1 never measured one at all.

  **RTO variance retest (2026-09-02): the leading hypothesis (KRaft
  controller failover) is refuted — and the real explanation for most
  of the original variance turned out to be the test harness itself,
  not Kafka.** Chat proposed a specific, testable mechanism: a
  partition-only leader reassignment is fast because the controller
  already has fresh metadata, but if the killed broker was *also* the
  active KRaft controller, that failure triggers controller failover
  (a Raft-quorum re-election among the 3 voters) before the partition
  election can even proceed — plausibly explaining a multi-second gap
  hiding inside one measured "RTO" number.

  Built `load-tests/kafka-controller-failover-rto-test.py` to test this
  directly: per trial, check the live KRaft controller
  (`kafka-metadata-quorum.sh describe --status`) and the per-partition
  leader map (`kafka-topics.sh --describe`), pick a partition whose
  leader either is or isn't the current controller (both occur
  naturally given this cluster's steady-state ~1-partition-per-broker
  leadership spread), kill that broker, and read the actual election
  timestamp from TRACE-level `controller.log`
  (`docker-compose.kafka-debug.yml`, the same overlay built during the
  unclean-election investigation) rather than inferring it from an
  external poll.

  **A serious measurement bug found before trusting the first full
  run**: the obvious way to poll for "has a new leader been elected
  yet" is calling `kafka-topics.sh --describe` in a loop — which is
  exactly what both this new script's first draft *and* the original
  `kafka-ha-demo.sh` Scenario 1 do. Timed directly: **a single
  `kafka-topics.sh` invocation costs ~0.96s, almost entirely JVM
  startup**, not the Kafka round-trip itself. `kafka-ha-demo.sh`'s
  polling loop (`for i in $(seq 1 60); do CUR=$(find_leader ...); ...;
  sleep 0.5; done`) therefore actually polls at roughly a 1.5s cadence
  (0.96s call + 0.5s sleep), not the apparent 0.5s — meaning the
  original 3713ms/14028ms/15476ms figures are best read as "however
  many ~1.5s-costly iterations it took to notice the change," not a
  continuous, fine-grained measurement of anything Kafka-internal. This
  is the same category of bug as the Postgres self-demotion
  investigation's whole-second `SECONDS`-builtin quantization
  (`docs/postgres-ha-scope.md`) — a coarse instrument masquerading as
  fine-grained — just a variable-cost-per-iteration version rather than
  a fixed quantization, which is exactly why it went unnoticed until
  someone timed a single call directly instead of trusting the loop's
  apparent resolution. Also found and fixed a second, smaller instance
  of a named pattern from this same doc's own history: this new
  script's `get_controller()` initially hardcoded its query target to
  `kafka-1`, the identical "monitoring helper's own hardcoded query
  target" mistake as this Scenario's original bug 1 above, and it broke
  for the identical reason (failing exactly when `kafka-1` is the
  broker just killed).

  Rebuilt the measurement around tailing `controller.log` directly
  (`docker compose exec kafka-N tail -c +OFFSET -f ...`, matching the
  `--since`-anchored live-tail approach already proven in the Postgres
  self-demotion script) and reading the actual
  `partition change for readings-N ... leader: OLD -> NEW` line's own
  timestamp — a real internal-decision measurement, not a polling
  artifact.

  ~~| Condition | Run 1 | Run 2 | Run 3 | Internal RTO band |
  |---|---|---|---|---|
  | Controller killed | 0.612s | 0.612s | 0.616s | 0.612–0.616s |
  | Non-controller killed | 0.616s | 0.619s | 0.662s | 0.616–0.662s |~~

  **Correction (2026-09-02): this table was itself wrong, found by a
  Chat review that refused to accept "topology variance" as an
  explanation for a 5x discrepancy against `kafka-ha-demo.sh`'s own
  production measurements (0.155s/0.115s) and insisted on the raw
  evidence instead.** The investigation script above had its own
  measurement bug — the same *category* of bug this whole stage was
  built to eliminate (a clock started at the wrong moment), just one
  level subtler than the JVM-per-call cost already found and fixed.
  `run_trial()` captured **two separate timestamps**: `kill_dt`, taken
  immediately on entering the function — *before* starting the two
  tail-watcher processes (each a `docker-exec`-based `get_log_size()`
  call plus a `Popen` spawn) and *before* an explicit `time.sleep(0.3)`
  — and `kill_wall_time`, taken correctly immediately before the real
  `docker compose stop`. The primary RTO calculation was passed the
  early, wrong one (`kill_dt`); `kill_wall_time` was computed correctly
  but only ever used for the secondary `external_confirm_s` metric.

  **A second review pass caught a real overclaim in how this fix was
  first reported, worth recording precisely rather than quietly
  correcting**: the first write-up said the gap was "measured directly
  at ~250ms for the tail-setup alone," but that figure actually came
  from timing a *different* script's own setup phase
  (`kafka-partition-rto.py`'s `main()`-to-tails-attached window), not
  this function's own `kill_dt`-to-`kill_wall_time` gap — an isolated
  component estimate presented as if it were the measured total. A
  bare `time.sleep(0.3)` alone is already 300ms of that figure; the
  two `Popen` spawns for the surviving brokers' `tail -f` processes
  plausibly add more on top (this exact investigation already
  established that `docker exec`/JVM-adjacent calls are not free — the
  `kafka-topics.sh` ~0.96s finding above is the direct precedent) — so
  ~250ms was never going to fully account for a ~460–550ms observed
  gap, and calling it "essentially the entire gap" wasn't yet earned by
  what had actually been measured. **Instrumented the real thing
  directly** (a temporary diagnostic printing the elapsed time from
  the exact point `kill_dt` used to be captured to where
  `kill_wall_time` is captured now, in this same function, not a
  proxy): **0.471s, 0.474s, 0.475s, 0.483s, 0.471s, 0.471s** across 6
  trials — a tight band, and it matches the per-run difference between
  the old buggy bands and the corrected ones below (0.457–0.548s,
  computed run-by-run) closely enough to close the arithmetic for real
  this time, not merely plausibly.

  Fixed by removing the early timestamp entirely and using the single,
  correctly-timed `kill_wall_time` (converted to the same
  timezone-aware `datetime` the log-matching code needs) for the actual
  RTO calculation. Re-ran the full 3×3 with the fix, twice — the second
  pass is also where the elapsed-time diagnostic above was measured,
  so both the fix and its own explanation share the same evidence:

  | Condition | Pass 1: Run 1 | Run 2 | Run 3 | Pass 2: Run 1 | Run 2 | Run 3 | 2026-09-03 re-run: Run 1 | Run 2 | Run 3 | Internal RTO band (n=9) |
  |---|---|---|---|---|---|---|---|---|---|---|
  | Controller killed | 0.155s | 0.138s | 0.142s | 0.167s | 0.151s | 0.153s | 0.144s | 0.122s | 0.141s | 0.122–0.167s |
  | Non-controller killed | 0.143s | 0.115s | 0.114s | 0.112s | 0.110s | 0.106s | 0.139s | 0.098s | 0.133s | 0.098–0.143s |

  **The rightmost 3 columns (2026-09-03) added once the archival-rigor
  gap this section originally disclosed was closed — see "Archival gap
  closed" under this stage's Raw evidence pointer, further down.**
  Labeled by date rather than "Pass 3" deliberately, to avoid colliding
  with this doc's own separate "pass 1/2/3" numbering for the
  `external_confirm_s` metric a few paragraphs below, which counts an
  earlier, RTO-buggy-but-`external_confirm_s`-clean run as its own pass
  1 — a different scheme than this table's Pass 1/Pass 2 (both already
  RTO-corrected). Widens both RTO bands slightly (two individual
  samples, 0.122s and 0.098s, land below the tighter n=6 range first
  reported) without changing the conclusion: the two conditions still
  overlap heavily.

  **This directly cross-validates against `kafka-ha-demo.sh`'s own
  production measurements, not just against itself.** Three real
  `kafka-ha-demo.sh` Scenario 1 runs exist in total: `0.155s` and
  `0.115s` from before controller-identity reporting was added to that
  script (their condition isn't known — reported honestly as unknown
  rather than assumed), and `0.119s` from the run immediately after,
  which explicitly confirmed and printed `killed broker was the active
  controller: no` (non-controller condition). All three values —
  `0.155s`, `0.115s`, `0.119s` — fall inside or immediately adjacent to
  the corrected bands above (controller 0.138–0.167s, non-controller
  0.106–0.143s), and the one run with a confirmed condition lands
  exactly inside its matching band. The investigation script's bug was
  real and the production port (`kafka-partition-rto.py`) was correct
  all along — confirmed by checking the actual numbers and the actual
  condition against each other, not by assuming either script was
  right.

  **Verdict: refuted, and now on solid footing.** The two conditions
  remain statistically indistinguishable — 0.138–0.167s vs.
  0.106–0.143s overlap directly — just at roughly a tenth the
  previously-reported (and now known-wrong) absolute scale. Whether the
  killed broker was the active KRaft controller has no measurable
  effect on the real partition-reassignment decision time in this
  3-broker cluster. The original variance (3.7s vs. 14–15.5s) reflects
  neither this mechanism nor, it turns out, a mechanism worth ~0.6s
  either — most of it was the test harness's own JVM-spawn cost in the
  original script, compounded by this investigation's own early-clock
  bug in its own retest, both now found and fixed in turn.

  **The secondary finding is upgraded from "single-sample, not yet
  confirmed" to a real, now four-times-replicated result** (12 total
  trials across the two corrected RTO passes, the original
  RTO-buggy-but-`external_confirm_s`-clean pass, and the 2026-09-03
  archival-rigor re-run, since this metric always used `kill_wall_time`
  and was never affected by either the original timing bug or the
  archival-filename bug): controller-killed
  `external_confirm_s` — pass 1 (original): 4.137s / 13.927s / 6.668s;
  pass 2 (corrected RTO, first run): 13.764s / 13.965s / 14.952s;
  pass 3 (corrected RTO, second run, the same pass the elapsed-time
  diagnostic above came from): 12.407s / 6.757s / 12.301s; pass 4
  (2026-09-03 archival-fix re-run): 4.0s / 12.656s / 15.153s.
  Non-controller-killed, same four passes: 3.801s / 3.741s / 3.737s;
  3.712s / 3.788s / 3.816s; 3.997s / 3.721s / 3.804s; 3.701s / 3.902s /
  3.853s. **Every single controller-killed sample (12 of 12) exceeds
  every single non-controller-killed sample (12 of 12)**
  — the non-controller band is consistently tight (3.70–4.00s across
  all four passes), while the controller band is wider and more
  variable (4.0–15.15s) but never once dips into non-controller range.
  Four independent passes showing the same non-overlapping ordering,
  even with real variability in the controller band's own width, is
  stronger confirmation than this project's usual three-repeat bar
  asks for on a single pass. This is
  strong, replicated evidence that the internal decision (~0.14s,
  statistically identical either way) and how quickly that decision
  becomes visible to a *freshly bootstrapping* client are genuinely
  separate things — the second one, plausibly because other brokers'
  local metadata caches need to sync with a brand-new controller rather
  than merely receive a forwarded update from an already-stable one,
  carries a real, ~4x, controller-identity-correlated cost. Not the
  mechanism originally proposed (that was about the internal election,
  now shown equally fast either way), but a genuine, now properly
  confirmed one all the same.

  **On Chat's ordered follow-up candidates (ISR catch-up lag, then
  GC-pause noise, only if controller identity didn't explain it)
  (2026-09-04): both tested directly, both refuted.** Neither explains
  the external-visibility split — the real mechanism remains unknown,
  reported here plainly rather than forced.

  **Candidate 1 (ISR catch-up lag) — refuted against the archived
  20260903T175404Z pass's raw `controller.log` slices**, not inferred.
  The target partition's own ISR shrink and leader handoff happen
  *instantly* (~0.14s, same timestamp as `rto_s`) in every trial,
  identically for both conditions — because it's driven by the *dying*
  broker's own graceful-shutdown handling (Kafka's `docker compose stop`
  sends `SIGTERM` first, and a still-alive, still-active old controller
  hands off leadership for its own partitions before it's actually
  gone), not by anything the *new* controller has to catch up on. There
  is no separate re-sync step for the target partition to be slow.

  **A more precise breakdown of where the real time actually goes**,
  found while checking candidate 1: extracting each archived
  controller-condition trial's `Becoming the active controller` log
  line shows controller activation itself is a roughly *constant*
  ~2.3–2.5s after the kill across all 3 trials (run1 2.506s, run2
  2.313s, run3 2.373s) — consistent, not what varies. The real variable
  component is the gap *after* activation, before `external_confirm_s`
  fires: 1.494s, 10.343s, 12.780s for the same 3 trials respectively.
  Controller activation time is not the source of the 4.0–15.15s spread;
  something happening *after* the new controller is already active is.

  **Candidate 2 (GC-pause noise) — refuted via a fresh, purpose-built
  live trial** (`load-tests/kafka-external-confirm-gc-check.py`), not
  archived-data analysis: the original 3 trials' GC logs no longer
  exist (Kafka has no persistent volume in this project, so those
  containers are long gone) and needed a new kill to check at all. GC
  logging is already enabled by default on this image
  (`-Xlog:gc*:file=.../kafkaServer-gc.log`, confirmed live via `ps aux`
  inside the container) — no new instrumentation needed. Killed the
  current controller (kafka-3), reproduced the same shape (activation
  2.394s after kill, `external_confirm_s` 14.087s, an 11.693s
  post-activation gap, matching the archived trials' high end), and
  checked the new controller's (kafka-1) own GC log for the entire
  window: **zero GC events of any kind, "Pause" or otherwise.** Verified
  the instrument itself first, not just trusted the null result — the
  same log file has real, correctly-formatted GC entries from the
  broker's own JVM startup moments earlier (two young-gen pauses,
  ~20ms/~18ms, both trivially fast and irrelevant), confirming GC
  logging genuinely works on this broker and genuinely logged nothing
  during the 11.7s gap, rather than the check silently finding nothing
  because it was broken.

  **Third, bounded round (2026-09-04, greenlit by Chat specifically
  because this shape — a test-harness/client-side cost wearing a
  Kafka-mechanism costume — is exactly this investigation's own
  already-proven bug pattern, found twice before): the mechanism is
  now precisely localized, not just "not GC and not ISR."** Checked
  whether AdminClient's own client-side retry/backoff behavior
  (queueing multiple attempts) accounts for the gap, by enabling
  `org.apache.kafka.clients` `DEBUG` logging for the `kafka-topics.sh
  --describe` call itself (no new instrumentation — this logging
  capability already exists via `KAFKA_LOG4J_OPTS` and
  `config/tools-log4j2.yaml`, just not normally turned on) and
  correlating every request/response pair's timestamp against a fresh
  controller-kill trial, live, the same way the GC check worked.

  **The original "client-side retry" framing turned out to be not
  quite right, but the same diagnostic technique found something more
  precise and more useful.** There's no retry loop visible at all — the
  AdminClient sends a normal, small burst of requests
  (`DescribeCluster`, `DescribeTopicPartitions`, `DescribeConfigs`,
  `ListPartitionReassignments`) as part of building one `--describe`
  call's output, and every one of them gets answered in single-digit
  milliseconds — **except `ListPartitionReassignments`, sent to the
  new controller specifically, which the controller does not answer
  for many seconds.** Trial 1: sent at kill+3.508s, answered at
  kill+22.108s — an **18.6s stall on this one request**, accounting for
  83% of that trial's total 22.496s `external_confirm_s`. A second live
  trial (a different new controller, kafka-2 this time, confirming this
  isn't specific to one broker) reproduced the identical shape at a
  different magnitude: a 10.521s stall on the same request, 74% of that
  trial's 14.259s total. Both trials' full request/response logs are
  archived, not just summarized.

  **Where this leaves it**: the mechanism is now precisely localized —
  the newly-active KRaft controller specifically stalls answering
  `ListPartitionReassignments` for a long, variable period after
  activation, while answering every other request type essentially
  instantly — but *why* that one request type stalls (a KRaft-controller
  internal implementation question: some queue, gate, or deferred
  initialization step specific to that request path) is one level
  deeper than this bounded round covers. Per Chat's explicit scope for
  this round, stopping here rather than opening a fourth, unscoped
  cycle into KRaft's own `QuorumController` internals. **Status: three
  candidates tested (ISR catch-up lag, GC-pause noise, AdminClient
  client-side retry/backoff), the first two cleanly refuted, the third
  reframed into a precise, reproducible, named bottleneck
  (`ListPartitionReassignments` response latency from a freshly-active
  controller) rather than confirmed or refuted as originally stated —
  genuinely resolved to that level of precision, not "still unknown."**

  Raw evidence for all three candidates above:
  `load-tests/kafka-external-confirm-gc-check.py` (the fresh GC-pause
  trial; kills the current controller, polls for actual activation
  rather than a fixed sleep, and dumps the new controller's GC log for
  the window — live-verified output: activation 2.394s after kill,
  `external_confirm_s` 14.087s, zero GC events);
  `load-tests/kafka-external-confirm-adminclient-check.py` (the
  AdminClient-debug-logging trial that found the
  `ListPartitionReassignments` bottleneck — enables `DEBUG` logging for
  `org.apache.kafka.clients` via `KAFKA_LOG4J_OPTS` around the same
  one-shot `--describe` call, no source changes). Both live runs' full
  request/response transcripts archived at
  `load-tests/results/kafka-external-confirm-adminclient-check-run{1,2}-*.txt`
  (moved there from `/tmp/` where they first landed — this investigation
  already has one documented archival-discipline gap from exactly this
  kind of oversight, worth not repeating). The GC-pause check's own
  live output was not similarly saved to a file at the time (only
  quoted in prose above) — trivially reproducible by re-running
  `kafka-external-confirm-gc-check.py`, but noted here rather than
  implied as archived when it isn't.

  Raw evidence for the original internal-RTO/external-visibility
  finding: `load-tests/kafka-controller-failover-rto-test.py`;
  `load-tests/results/kafka-controller-failover-rto-results.json` and
  its per-trial `controller.log` slices (pass 2/corrected only — this
  fixed filename scheme meant re-running the script a second time for
  the elapsed-time diagnostic silently overwrote pass 1's raw log
  files with pass 1's own condition/run numbering; pass 1's numbers
  survive only as the quoted terminal transcript above, not as
  separately archived files — worth naming as a real gap in this
  investigation's own archival discipline, not glossed over just
  because the numbers themselves were already captured in prose).

  **Archival gap closed (2026-09-03), by fixing the root cause rather
  than just re-running once more.** The script's filename scheme now
  takes a `--pass-label` argument (default: a UTC timestamp), namespacing
  every per-trial `controller.log` slice and the results JSON so a future
  re-run can never again silently collide with and overwrite a prior
  pass's evidence the way pass 2 overwrote pass 1. Re-ran the full
  6-trial suite once under the fixed script
  (`kafka-controller-failover-rto-results-20260903T175404Z.json`, label
  `20260903T175404Z`) specifically to backfill a third, fully-archived
  data point rather than leave the record at "one archived pass plus one
  prose-only quote." **Confirmed live that pass 2's original files were
  genuinely untouched** (unchanged mtimes) before trusting the new run's
  own output.

  This third pass's raw numbers: controller-killed 0.144s/0.122s/0.141s,
  non-controller-killed 0.139s/0.098s/0.133s. **Reported precisely
  rather than smoothed to fit**: two individual samples (0.122s and
  0.098s) land just below the previously-stated 0.138–0.167s and
  0.106–0.143s bands — those bands were never a hard theoretical limit,
  just the observed range of the first 6 corrected trials, and a third
  independent pass finding the true range is a little wider is the
  expected, healthy outcome of adding more data, not a contradiction of
  anything. **The actual conclusion is unaffected and now more strongly
  evidenced**: the two conditions' ranges (controller 0.122–0.144s,
  non-controller 0.098–0.139s) still overlap heavily, consistent with
  "no measurable internal-RTO effect from controller identity" across
  all 3 passes now, not just 2. The secondary `external_confirm_s`
  finding is strengthened further still: this pass's 3 controller-killed
  values (4.0s, 12.656s, 15.153s) each exceed all 3 of its
  non-controller-killed values (3.701s, 3.902s, 3.853s), extending the
  clean non-overlapping separation from 9-of-9 to **12 of 12** samples
  across the 4 independent passes that section's own numbering counts
  (see the fully updated `external_confirm_s` writeup further down for
  the complete per-pass breakdown).

  Updated raw evidence: `load-tests/results/*-20260903T175404Z*` (12
  per-trial `controller.log` slices plus the results JSON, this pass);
  `load-tests/results/*-BUGGY-early-kill-dt*`
  and `load-tests/results/*-CONTAMINATED-jvm-poll-overhead*` (both
  earlier, wrong full runs, kept and clearly labeled rather than
  deleted, as the evidence for their respective measurement-bug
  findings); `load-tests/results/kafka-ha-demo-scenario1-*/` (one
  archived production run — the `0.119s` one, run after this evidence
  archival was added to the script; the earlier `0.155s`/`0.115s`
  production runs predate it and survive only in this doc's own prose,
  same archival gap named above); per-trial `controller.log` slices
  alongside the investigation results.

  **The fix was carried back into `kafka-ha-demo.sh` itself, not left in
  the disposable investigation script (2026-09-02, flagged by a Chat
  review before this was considered done)**: the finding above is about
  the *actual production test script* — the one that runs on every
  normal invocation, not a one-off — so leaving it unfixed would have
  meant every future run kept producing the same kind of misleading
  numbers this investigation just spent real effort explaining. New
  `load-tests/kafka-partition-rto.py`, a reusable version of the
  investigation script's log-tail measurement (same technique, generalized
  into a small CLI: watches the surviving brokers' `controller.log` for
  the specific partition's leader-change decision and reports RTO from
  that timestamp). `kafka-ha-demo.sh`'s Scenario 1 now calls it instead
  of the JVM-cost-dominated `kafka-topics.sh` polling loop.

  **The debug overlay is a required, hard-checked prerequisite for
  Scenario 1, not documented-but-skippable** — deliberately stricter
  than the unclean-election scripts' own precedent (which treat it as
  optional/best-effort evidence on top of an otherwise-valid test),
  because here the log-based read *is* the measurement itself, not
  bonus context. A check at the very top of Scenario 1 greps the live
  `log4j2.yaml` for `org.apache.kafka.controller` at `DEBUG`/`TRACE`
  and `exit 1`s with the exact command to fix it if not — before the
  scenario disturbs anything (the canary write, the kill) — rather than
  silently falling back to the old, misleading polling method.
  `kafka-partition-rto.py` carries an identical check of its own as a
  second line of defense. This was a real decision point, not an
  afterthought: the alternative (permanently raising the stock,
  always-on Kafka logging config to avoid needing the overlay at all)
  was considered and explicitly declined, matching this project's own
  minimal-scope ethos already applied elsewhere (the outbox pattern
  built, measured, and retired rather than kept "just in case";
  observability-only tenancy instead of full isolation) — a capability
  this rarely needed doesn't justify a permanent production-adjacent
  config change.

  **Two real bugs found getting this working end to end, both fixed
  before trusting the result:**
  1. **A timing-direction bug**: the kill-instant signal was originally
     written to the handoff file *after* `docker compose stop` returned,
     not before issuing it — producing a genuinely negative measured RTO
     (`-2.804s`) on the first real run. Root cause: Kafka's own
     SIGTERM-triggered controlled shutdown can relinquish partition
     leadership *while* `docker compose stop` is still waiting for the
     container to fully exit, so the real decision can be logged before
     the stop command ever returns. Fixed by writing the signal
     immediately before issuing the stop, matching the investigation
     script's own correct ordering (`kill_wall_time = time.time()`
     captured right before `docker compose stop`, not after).
  2. **A stale-variable bug in the final results summary**: after
     renaming the RTO variable from `RTO_MS` to `RTO_S` throughout the
     scenario, one reference in the script's own end-of-run "Results"
     section was missed, so a fully correct `0.155s` measurement mid-run
     still printed `measured RTO: N/Ams` in the final summary — the
     exact kind of thing that's easy to miss without actually running
     the script to completion rather than trusting the diff. Both fixed
     and reconfirmed via two full end-to-end runs (`0.155s` and
     `0.115s`), including the corrected final summary line.

  **A separate, unrelated regression caught and fixed along the way**:
  this session's earlier idempotency-key work
  (`docs/idempotency-scope.md`) made `Idempotency-Key` a required header
  on `POST /readings`, and every load-tests `.sh` script that posts
  readings directly (not through JMeter/Bruno, which were already fixed)
  had been missed — `kafka-ha-demo.sh`, `kafka-acks-gap-repro.sh`,
  `kafka-leader-failover-rto.sh`, `postgres-app-primary-failure-test.sh`,
  and `redis-app-primary-failure-test.sh` would all have started failing
  with `400`s on their very next run. Found only because actually running
  `kafka-ha-demo.sh` to validate this fix hit it directly. Fixed across
  all 8 call sites in all 5 scripts, not just the one that happened to be
  under test.

  **Scenario 2's own result, now trustworthy for the first time since
  it was pointed at a live target**: confirms real data loss when the
  outage exceeds `delivery.timeout.ms`, via the Traefik-routed query —
  see the Quorum-loss test entry below for the original finding this
  reconfirms, now on solid footing rather than querying a retired
  container.

  **One incident worth keeping on record even though it produced no
  real Kafka finding**: mid-investigation, editing the test script's
  file while an earlier invocation of it was still executing corrupted
  what that running process read for the remainder of its execution — a
  bash mechanics issue (scripts are read incrementally as they run, not
  loaded wholesale), not a logic bug in the script itself. The corrupted
  run aborted mid-`Scenario 2` before it could restart the brokers it
  had stopped, leaving the cluster genuinely degraded; found by checking
  directly rather than assuming a clean exit meant a clean cluster, and
  recovered by restarting the affected brokers before re-running clean.
  See `docs/cross-project-lessons.md` for the general lesson.
- **Quorum-loss test** — kill 2 of 3 controller-eligible brokers
  deliberately. The correct outcome is the cluster refusing to elect a
  leader or accept writes it can't safely commit — confirm it fails safe
  (stalls/rejects) rather than failing unsafe (accepts writes it can't
  guarantee, risking split-brain or data loss). This is the test that
  proves quorum-based safety was actually built, not assumed. **Status:
  done** — the 150s scenario, tested multiple times, confirmed real
  permanent data loss when the outage exceeded the (then-undeclared)
  `delivery.timeout.ms` default; see `docs/resilience-scope.md`'s
  "Outcome" section for the full account of what was built in response
  and what was ultimately retired.
- **Rolling maintenance test** — take one broker offline gracefully (the
  "planned maintenance window" scenario), confirm zero client-visible
  downtime while at 2-of-3, bring it back online, confirm it rejoins and
  resyncs cleanly. This is the test that matches the real-world
  maintenance-notice pattern (planned host migration, planned upgrade)
  from actual production experience — and, paired with the quorum-loss
  test above, the two together validate the actual risk scenario: a
  planned reduction to 2 is safe on its own, but a second unrelated loss
  landing during that same window is not. **Status: done** — Scenario 3,
  all 3 brokers restarted sequentially, 30/30 requests succeeded, zero
  downtime.

**Deferred:** equivalent test suites for Redis (Sentinel failover) and
Postgres (Patroni failover, or manual-failover verification if Patroni
is scoped out) — write these when each layer's own HA scope doc exists,
per `docs/ha-scope.md`'s revisit triggers. Don't design them speculatively
ahead of that scope decision being made. **Note (2026-08-28)**:
`ha-scope.md`'s own revisit trigger for Redis ("once Kafka's multi-broker
pass is built, tested, and its own status log closed out") is arguably
now satisfied — this is a new scope decision to make explicitly, not
unfinished work from this pass.

## Application-level validation: confirmed clean, no remediation needed (resolved 2026-09-02)

**Found during the Postgres pass, applying here on inspection, not
assumed.** `docs/ha-scope.md` carries a standing lesson: Postgres's
6-stage HA pass validated the Patroni/Consul topology entirely via
direct `psql`/`patronictl`, and never actually confirmed the application
itself (real requests through Traefik → API → Kafka producer) survives
any of the failure modes tested. Redis's pass had the same gap, confirmed
directly (its chaos scripts drove and checked state via `redis-cli`
throughout). Whether this Kafka doc had the same gap was genuinely
unclear from the document alone and needed confirming, not assuming
either way.

**Resolved: checked `kafka-ha-demo.sh` directly rather than assumed.**
Every scenario logs in for a real JWT and sends readings via
authenticated `POST /api/v1/readings` through Traefik, exercising the
app's actual Spring Kafka producer end to end — not a direct
producer/consumer script bypassing the app. **Kafka's pass was ahead of
both Postgres's and Redis's on this specific dimension from the start**,
which is itself worth stating plainly rather than assumed to match the
other two by default — the asymmetry across the three passes turned out
to be real, not an oversight in how this doc was checked.

**Subsequent work (2026-09-02), separate from this methodology
question**: the failover/RTO test's *rigor* still had real gaps even
though its traffic generation was already app-real — Scenario 1 killed
a fixed broker regardless of whether it led any partition in use, and
never measured actual RTO. That work is written up in full under the
"Failover / RTO test" entry above (3 real bugs found and fixed, 3 valid
RTO measurements, Scenario 2's durability check repointed to a live
target). Worth keeping these two findings distinct: this section
confirms the test always exercised real app traffic; the RTO work above
confirms the test now also targets the right broker and measures the
right number. Both were real, independent gaps — closing one didn't
imply the other was already closed.
