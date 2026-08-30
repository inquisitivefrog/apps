# grid-meter-app — Multi-tenancy scope (customer/account concept)

## Why this doc exists

Blast-radius reporting, per-customer outage tracking, feature-flag
adoption by customer, and "can we support a customer of size N" all
require a customer/account concept the app doesn't have today, per
`docs/observability-taxonomy.md`. This is a genuine data-model and scope
decision — following `CLAUDE.md`'s own convention of checking in before
committing to structural choices not already pinned down, rather than
adding an entity unilaterally.

## Current state (why this is actually blocked)

- `Meter` has no owner field of any kind.
- `User` is explicitly single-seed, no role column, no self-registration
  endpoint — a deliberate choice per `api-and-data-model.md`, not an
  oversight, but one that means there's no existing multi-user concept to
  extend.
- No `Account`/`Customer`/`Organization` entity exists anywhere in the
  schema. There is currently no way to answer "which customer does this
  meter belong to" at all, let alone report on it.

## Decision: add a minimal `Customer` entity, scoped to what's actually needed

**Confirmed 2026-08-27: observability-only tenancy** (the smaller of the
two options below) — add the entity, propagate `customerId` through
logs/traces for reporting, with no change to API access control. Every
authenticated user still sees every customer's data, exactly as today.

Two very different sizes of feature hide under "multi-tenancy," and only
one is needed to unblock the reporting questions raised:

- **Full multi-tenant SaaS** — enforced API-level tenant isolation (a
  customer can only ever see their own meters/readings), per-tenant
  quotas, tenant-scoped JWT claims checked on every query, a cross-tenant
  admin/support role. A substantial feature — real complexity added to
  every controller/service/repository query in the app.
- **Observability-only tenancy (recommended for this pass)** — add the
  entity and propagate `customerId` through logs/traces for reporting
  purposes, without changing API access control at all. Every
  authenticated user still sees everything, exactly as today; the only
  change is that requests and rows now carry a `customerId` a report or
  post-incident query can filter by.

Recommend the smaller version, matching the minimal-scope reasoning
already applied elsewhere in this project (the same "don't build
speculative structure ahead of an actual need" logic used to defer
Postgres HA and to originally rule Terraform out entirely). Full tenant
isolation is worth its own future decision doc if this project's scope
ever grows to model real customer-facing access boundaries — not
something to fold in silently alongside a reporting-only need.

## Data model changes

- **New `Customer` entity**: `id` (UUID), `name`, `createdAt`/`updatedAt`.
  Deliberately minimal — no billing fields, no plan/tier field yet (a
  subscription-tier concept from the feature-flag discussion in
  `docs/observability-taxonomy.md` would hang off here later, but isn't
  needed to unblock reporting now).
- **`Meter.customerId`**: FK → `Customer`. Every meter belongs to exactly
  one customer — physical meters are always owned by someone in the real
  world this app simulates, so an unowned meter isn't a meaningful state.
- **`User.customerId`**: FK → `Customer`, one customer per user for this
  pass. A many-to-many User↔Customer model (multiple users per customer)
  is a reasonable future enhancement, not needed to unblock reporting.
- **Flyway migration**: a new `V4__create_customers_table.sql`, following
  the existing `V3__create_users_table.sql` precedent — seed a default
  customer, assign the existing `demo` user and any existing seed/test
  meters to it.
- **JWT claims**: add `customerId` to the token issued at login, mirroring
  the existing "single `ROLE_USER` authority granted at the Security
  layer" pattern — avoids a per-request DB lookup to resolve which
  customer a request belongs to.

## Propagation: logs and traces, not raw Prometheus labels

Worth stating carefully, since it's a real technical trap and a
correction to something said earlier in this conversation: `customerId`
should become a Loki log field (via MDC) and a Tempo trace span
attribute — both are built for exactly this kind of per-request,
high-cardinality context. It should **not** become a raw Prometheus
metric label.

Earlier in this conversation, "propagate `customerId` through
metrics/logs/traces" was suggested without this caveat — that's the part
to walk back. Prometheus's data model creates a distinct time series per
unique label-value combination; a `customerId` label directly on a
request-count or latency metric means the series count grows with the
customer count, and Prometheus's own documented guidance is that storage
and query performance degrade badly past roughly a few hundred to
low-thousands of distinct values on a single label. An interview-demo
customer count wouldn't hit that wall today, but building the habit now —
rather than after a real cardinality incident — is exactly the kind of
judgment worth demonstrating.

The corrected pattern: query Loki/Tempo by `customerId` for blast-radius
reporting, joined against an incident alert's own known firing window.
Reserve Prometheus for aggregate or intentionally-bucketed views only
(a fixed small set of customer tiers, or a top-N-by-volume breakdown) —
never raw per-customer cardinality.

## Blast-radius report shape (unblocked once this ships)

"N users across M customers were affected between T1 and T2" becomes a
Loki query filtered to the incident alert's firing window, grouped by
`customerId`, counting distinct `userId`s — a saved query or dashboard
panel, not a new alerting mechanism. This matches
`docs/observability-taxonomy.md`'s placement of blast-radius reporting
under Reports & dashboards, explicitly not under incident alerts.

## Testing implications

**Status (2026-08-27, updated): fully closed.** Both testing-implication
items below are now implemented — `MeterComponentTest` and
`ReadingComponentTest` each got a
`search_returns...AcrossAllCustomers_documentingCurrentNonIsolation` test,
seeding a real second `Customer` and asserting search returns data across
both. Suite is at 60 tests (was 58), plus 16/16 black-box `*ApiIT`, all
re-run multiple times rather than trusted on a single pass.

**Bonus finding**: writing the `ReadingComponentTest` version surfaced a
real, previously-latent bug — its `awaitPersisted()` helper never called
`.ignoreExceptions()` on its Awaitility poll, making it fully dependent on
winning a race against Kafka consumer lag on the very first polling
attempt. Never triggered before because no earlier test ingested two
readings back-to-back under full-suite load. Reproduced 2/2 times before
the fix, clean 3/3 times after — exactly the outcome this section's
"verify, don't assume" framing was arguing for: the test that looked like
pure overhead found a real bug nothing else had.

- Component tests need **at least 2 seeded customers** with distinct
  meters/readings — even though this pass doesn't enforce isolation,
  having real multi-customer seed data is what makes a future
  isolation-enforcement test writable later without a data-model change
  at that point.
- A specific, cheap regression worth adding now: assert that
  `GET /meters` and `GET /readings` currently return data **across all**
  customers, documenting today's intentional non-isolation as a real,
  tested behavior. If isolation is added later, the suite has to be
  deliberately updated rather than isolation silently regressing
  unnoticed in either direction. **This is the one test that actually
  confirms this pass didn't unintentionally change access behavior** —
  without it, "nothing changed" is an assumption, not a verified fact,
  which is inconsistent with how the rest of this project treats claims
  like this (see the HikariCP and Kafka-outage investigations, both of
  which checked real behavior rather than trusting it).

## Explicitly deferred

- **Enforced API-level tenant isolation** (per-customer query scoping,
  cross-tenant admin role) — its own future decision doc, if/when this
  project's scope grows to need real customer-facing access boundaries.
- **Multiple users per customer** (many-to-many User↔Customer) — a
  straightforward extension, not needed to unblock current reporting
  needs.
- **Subscription tier / plan field on `Customer`** — natural home for the
  feature-flag subscription concept from `docs/observability-taxonomy.md`,
  deferred until feature flags themselves get their own scope decision.
