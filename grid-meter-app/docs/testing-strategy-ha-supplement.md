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
  same fix.** The original gap (`kafka-ha-demo.sh` Scenario 1 stopping
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
