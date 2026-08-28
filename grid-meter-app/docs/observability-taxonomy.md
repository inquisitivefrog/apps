# grid-meter-app — Observability signal taxonomy: beyond incidents

## Why this doc exists

`testing-strategy-ha-supplement.md` drew a first line between incident
alerts and trend alerts. A broader question — beyond incidents, what else
is worth observing, and what type is each — surfaced enough distinct
signal shapes across one session's worth of SRE-experience questions that
they deserve an organized reference rather than accreting ad hoc into
whichever doc happened to be open when each one came up.

## The core distinction: page-worthy vs. plan-ahead vs. record-only

Three different reader intents, and matching a signal's delivery
mechanism to the wrong one is itself a reliability problem — paging
someone at 3am for a slope that matures in Q3 is exactly how real alert
fatigue starts, and a page-worthy signal quietly buried in a weekly report
is a gap nobody notices until it's too late.

1. **Page-worthy** → incident alerts. Real-time, act now.
2. **Plan-ahead** → trend alerts. Slope-based, a days-to-months horizon,
   never pages anyone.
3. **Record-only** → notices, reports, dashboards. Retrospective or
   point-in-time visibility; exists so the answer is there when someone
   asks, not to interrupt anyone in the moment.

## 1. Incident alerts (existing category — two sub-types)

- **Threshold alerts** — the existing 3 rules (`API is down`, `High HTTP
  error rate`, `Tomcat thread pool saturated`). Exceed a ceiling, for a
  sustained window, page now.
- **Anomaly / undershoot alerts** — a genuinely different detection shape,
  not just a smaller version of a threshold alert: a metric *dropping
  below* its expected baseline rather than exceeding a ceiling.
  "AuthN/primary-URL traffic went to zero" is the motivating case — it
  can't use an absolute floor (that would misfire during a real 3am quiet
  period), so it has to compare against the same time last week/day,
  which only works once the seasonal baseline in §4 below actually
  exists. Real triggers this catches that threshold alerts structurally
  can't: a DDoS suppressing legitimate traffic (traffic pattern looks
  wrong, not necessarily overloaded), an upstream provider outage cutting
  off inbound requests before they ever reach Traefik, or a broken deploy
  that silently drops requests before they reach a controller (nothing
  errors, nothing arrives).
- **Synthetic-canary-sourced incidents** — not a new alert shape but a new
  *signal source* worth naming: a scheduled probe that logs in via
  `/api/v1/auth/login` and exercises one or two representative endpoints,
  exported as its own labeled metric distinct from real-traffic metrics.
  The existing threshold/anomaly logic layers on top of it unchanged —
  what's new is that it catches "technically up, functionally broken"
  gaps (AuthN quietly failing, a route silently misconfigured) that
  neither infrastructure health checks nor real-traffic metrics reveal on
  a quiet night with little organic traffic to fail.

**Note (2026-08-28)**: a real instance of the general "infrastructure
health check vs. actual functional health" gap this section describes
was found and fixed during the resilience-scope.md investigation —
Traefik had no health check for `api` at all, and once one was added
(driven by `/actuator/health`'s aggregate status), it initially
over-corrected by taking down unrelated traffic during a Kafka-only
degradation. See `resilience-scope.md`'s "Outcome" section for the full
account. Not a new alert-taxonomy category, but a concrete example of
why matching a check's scope to what it actually claims to verify
matters in practice, not just in principle.

**`reading_delivery_failures_total` is discussed in §3, not here** —
initially built as a fourth incident alert, then reclassified the same
day to `alert_class: notice`. *Why* it moved, not just that it exists, is
the interesting part — see §3's "Delivery-failure notices" entry.

## 2. Trend alerts (existing category — refined into three sub-types)

- **Resource-capacity trend** — the existing writer-node example (CPU/
  connections/disk climbing over days-to-weeks). Phrased as a *projected
  exhaustion date*, not a threshold — "hits 80% by \<date\>," which is
  what turns autoscaling-already-kicking-in (reactive, already late) into
  a budgeting conversation (proactive).
- **Meta / derivative trend** — a trend *of* a trend: the rate of
  autoscale-out events itself climbing over time is a proxy for "the
  baseline no longer fits demand," distinct from any single scale-out
  event being a problem on its own. Requires scale events to exist as
  their own counted signal first (§3).
- **Adoption / usage trend** — new: a feature flag's beta-cohort or
  subscriber *count trending* over time, not just its current value.
  Useful for capacity-planning a beta rollout's likely blast radius before
  flipping a flag to 100%, rather than discovering the load impact only
  after the fact.

## 3. Notices (event-triggered, discrete, record-only)

Not time-series, not threshold-based — something happened, worth a
durable record, never worth a page on its own.

- **Failover-event notices** — leader changed, no client-visible impact
  (already named in `testing-strategy-ha-supplement.md`; formalized here
  as belonging to this category).
- **Scale-event notices** — an autoscale-out/in actually occurred. Feeds
  the meta-trend above; also just useful correlation context when
  reviewing "was performance different because a scale event just
  happened."
- **Feature-flag state-change notices** — a flag was toggled, a cohort was
  expanded or contracted. An audit trail — the first thing worth checking
  when investigating "did behavior change because of a flag flip," not
  something anyone needs pushed to them in real time.
- **Circuit-breaker state-change notices** (see the resilience discussion
  from the prior session) — breaker opened / half-opened / closed.
  Informational on its own; becomes trend-worthy the moment open-events
  start climbing in frequency (a breaker flapping is itself a slope, not
  just a discrete event). **Status (2026-08-28): the circuit breaker
  itself remains unbuilt — see `resilience-scope.md`'s open decision on
  it — so this notice type has no source yet. Still a valid design,
  waiting on its upstream signal to exist.**
- **Delivery-failure notices** — added 2026-08-28, reclassified the same
  day: a Kafka publish permanently failing after `delivery.timeout.ms`
  expires during a sustained outage
  (`reading_delivery_failures_total`, `alert_class: notice`). Initially
  implemented as an incident alert, on the reasoning that the event was
  page-worthy on its own since the data is permanently lost, not just
  delayed. Reclassified to a notice on reflection: "permanently lost"
  doesn't imply "worth interrupting someone about" once the redo-path
  test (see `resilience-scope.md`'s "Outcome" section) established the
  lost data has no real downstream consequence in this app's actual
  scope — the same reasoning that retired the outbox pattern applies
  here too, just to the alerting decision instead of the durability one.
  A durable record (the counter + an `ERROR` log line + this rule,
  visible in Grafana's alert history) is what the redo-path conclusion
  actually calls for, not a page. Worth keeping this reversal on record
  rather than editing it away: it's a case where the same underlying
  event (a durable record of "something failed") could reasonably sit in
  either category, and the deciding factor is scope-dependent, not
  structural — a project where lost readings *did* have a real
  consequence (billing, regulatory) would correctly classify the
  identical event as an incident.

## 4. Reports & dashboards (retrospective or point-in-time, never alert-triggered)

- **Rolling-totals seasonal/cyclical report** — the Q4-is-busiest,
  spring/autumn convention-week spikes, 2.5%-monthly-growth-except-for-
  acquisitions picture. Coarse, long-horizon, low-cardinality rollups —
  explicitly *not* "keep all of it," matching the retention reasoning
  already in `testing-strategy-ha-supplement.md`. This is also the data
  source the anomaly/undershoot alert in §1 needs to define "expected
  baseline" against.
- **Quiet-period heatmap** — day-of-week × hour-of-day traffic map, for
  identifying real maintenance-window candidates rather than guessing.
- **High-water-mark / max-usage report** — historical peak per resource
  dimension (most requests, most data stored, most sustained load) per
  the "can we support a customer of size N" question. Mostly a
  Prometheus `max_over_time()` query over long-enough retention, not a
  hand-rolled cache — the retention window is the real constraint, not
  the query.
- **Blast-radius / customer-impact report** — post-incident, retrospective:
  "N users across M customers were affected between T1 and T2." **Blocked
  on a real gap**: this app has no customer/account concept today (no
  `Account` entity, `User` is explicitly single-seed, `Meter` has no
  owner). The report's *shape* can be designed now; it can't be populated
  until a `customer_id` exists as an actual label on logs/metrics/traces,
  not just a database column. Tracked as its own prerequisite decision —
  see "Queued docs" below.
- **Feature-flag adoption dashboard** — point-in-time counts (`Total Beta
  Users`, `Total Feature X Subscribers`), keyed to hashed/anonymized user
  aliases per the stated preference. Same underlying prerequisite as
  blast-radius reporting where the count needs to be broken out
  per-customer rather than only in aggregate.

## Summary table

| Category | Timescale | Pages anyone? | Detection shape |
|---|---|---|---|
| Threshold incident alert | Real-time | Yes | Exceeds ceiling, sustained window |
| Anomaly/undershoot alert | Real-time | Yes | Drops below expected baseline |
| Resource-capacity trend | Days–weeks | No | Slope → projected date |
| Meta/derivative trend | Weeks–months | No | Slope of an event-rate |
| Adoption/usage trend | Days–weeks | No | Slope of a count |
| Notices (failover/scale/flag/breaker/delivery-failure) | Instant | No | Discrete event, logged |
| Seasonal/cyclical report | Months–years | No | Scheduled rollup |
| Quiet-period heatmap | Recurring | No | Aggregated pattern |
| High-water-mark report | On-demand | No | Historical max query |
| Blast-radius report | Post-incident | No | Retrospective join |

## Queued docs

Two follow-on scope decisions this taxonomy surfaces but doesn't resolve:

- **`docs/multi-tenancy-scope.md`** — the customer/account entity decision
  blocking blast-radius reporting and per-customer outage tracking.
  Written and implemented (observability-only tenancy) as of 2026-08-27.
- **`docs/resilience-scope.md`** — Resilience4j (bounded retry + circuit
  breaker) and confirming `/actuator/health`'s aggregate status actually
  drives Traefik's routing decisions. Written; the health-check item is
  resolved (see its "Outcome" section — Traefik's check was found
  missing entirely, then built, then corrected once it over-blocked
  unrelated traffic). **Correction (2026-08-28): this doc no longer
  covers a transactional-outbox pattern** — one was built, measured
  against a real sustained outage, and deliberately retired once the
  redo-path test was applied honestly to this project's actual scope
  (synthetic data, no billing, no downstream consumer). The circuit
  breaker itself remains unbuilt and is tracked there as an open,
  undecided item — distinct from the outbox, which was evaluated and
  declined, not merely deferred.
