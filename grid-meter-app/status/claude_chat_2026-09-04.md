# grid-meter-app — Status: 2026-09-04 (Claude Chat)

**Provenance note**: this file replaces an earlier `claude_chat_2026-09-05.md`,
which turned out to be misdated — it merged this day's work with 2026-09-06's
k8s Kafka HA work into one narrative, self-labeled 09-05 without checking
against git. No commits exist for 2026-09-05 at all; that date was a false
memory, not a real gap. Corrected via direct git log review. Full mechanism
detail for everything below lives in `status/claude_code_2026-09-04.md`
(commits `60b7476` through `9330a1a`); this file covers the Chat-side
decisions and reviews layered on top of that work.

## Done — doc-drift audit and CLAUDE.md standing lesson

- Reviewed a Claude Code audit of doc drift across the repo. Three
  "needs action" findings, all confirmed real: `observability-taxonomy.md`
  still called the circuit breaker "unbuilt" after it shipped;
  `vendor-bug-report-process.md`'s status table still showed Redis/Postgres
  HA as "Not started" after both closed; `architecture.md`/`identity.md`
  still described Terraform/TLS as out-of-scope after
  `cloud-deployment-scope.md` reversed both decisions on 2026-08-27.
  Directed Claude Code to fix all four as mechanical doc-sync — done,
  commit `60b7476`.
- Drafted and approved a new `CLAUDE.md` standing-lessons entry: "chaos-tested
  infrastructure is not the same claim as a protected application" — the
  cross-cutting finding from the Postgres/Redis/Kafka HA passes that
  infrastructure-level chaos testing can pass clean while the app was never
  actually wired to what was tested. User transferred this into the repo
  directly (hand-edited, not a Claude Code commit) after reviewing the exact
  wording.
- The cloud-deployment scope decision itself (build vs. shelve vs.
  sync-only) was explicitly left with the user, parked behind the (at the
  time unscoped) k8s Kafka HA follow-up slice.

## Done — E2E test tier, Phases 1–3, six batches

Scoped and reviewed batch-by-batch rather than handed off as one large task,
specifically so a failure would be easy to localize:

- **Batch 1** — Playwright scaffolding. One structural check-in first
  (top-level `e2e/`, not nested under `frontend/` — the deciding factor was
  that Phase 2b/2c would test Grafana/Consul/Kafka/Redis/Postgres directly,
  which have no relationship to the frontend package). `baseURL` confirmed
  against Traefik's real port-80 routing, not the Vite dev-server proxy.
- **Batch 2a** — app critical-path journeys (login/logout, meter
  create-edit-delete, readings search/filter/pagination, the no-edit-
  affordance negative assertion). Reviewed and approved a real bug found in
  the test itself (a React-Router navigation race), and a follow-up seed-data
  design call for the readings journey (self-contained beforeAll/afterAll,
  polling past the async Kafka-ingest gap rather than fire-and-forget).
- **Batch 2b** — observability UI fixtures (Grafana, Consul). Reviewed two
  live-verification findings before they went into the fixture: Grafana has
  no login at all (anonymous Admin, deliberate dev config, not a bug) and
  Consul's UI wasn't host-reachable until a port mapping was added — approved
  exposing it (Consul's UI is a genuine dashboard, not just a raw API) over
  dropping the check.
- **Batch 2c** — CLI connectivity checks (Redis, Postgres, Kafka, Consul).
  Approved the live-verification-first design after Batch 2b's pattern of
  "guessable-wrong" ports/credentials repeated for two more services.
- **Resource-measurement pass** — reviewed real numbers before scoping CI:
  combined Docker + host-native Chromium memory (~4.6 GiB) fits a standard
  GitHub-hosted runner's 7 GB ceiling with real headroom, but peak container
  CPU (270–293%) already exceeds a standard runner's 2-vCPU ceiling.
  Clarified for the user, at their request, the actual distinction between
  "deploying the app to AWS/GCP" (a separate, not-yet-started track) and
  "where CI test jobs execute" (this decision) — they're unrelated questions
  that are easy to conflate.
- **Decision: self-hosted runner on the user's own Mac**, not a paid larger
  GitHub-hosted tier and not a rented cloud VM — free, matches what was
  already measured working, and avoids adding a second unresolved thread on
  top of pre-existing CI flakiness the user flagged wanting to reduce, not
  increase.
- **Phase 3** — self-hosted E2E CI workflow. User registered the runner
  themselves (`config.sh`/`svc.sh`) after Claude Code's own attempt was
  correctly blocked by the auto-mode classifier as a standing,
  security-relevant change — the right call, since this permanently links
  the Mac to the repo such that any future push can execute code on it.
  Reviewed and approved the empirically-answered 112s-vs-26s Patroni
  convergence question (real connection-refused reproduction, not inferred
  from state names) and the two self-hosted-macOS keychain/credential-helper
  bugs found getting the runner green. **4 consecutive real green runs**
  confirmed via log, not just the checkmark.

## Done — two independent bug-fix threads, same day

- **`scripts/run-black-box-api-tests.sh`'s "no such service: postgres"**
  (two CI screenshots surfaced this). Reviewed and approved a deliberate
  pattern deviation: rather than copying `kafka-ha-demo.sh`'s
  Traefik/`PGPASSWORD` fix, the actual fix just removed a dead service name,
  relying on `api`'s own `depends_on` graph instead of hand-duplicating a
  service list — more robust, can't drift out of sync again. Verified live
  (18/18 Failsafe tests). A follow-up repo-wide sweep (prompted by asking
  whether the 2026-09-03 sweep's scope had a gap — it did) found exactly one
  more real instance.
- **`load-tests/chaos-demo.sh`'s same stale `postgres` reference.** This one
  needed a real decision, not a mechanical rename — approved reframing
  `postgres` → `patroni-1` as a single-node-loss "should be a non-event"
  case (matching `kafka-1`'s existing framing under the 3-node cluster)
  over preserving total-outage wording for what's now the boring/expected
  case. A genuine full-cluster-outage scenario was named as a legitimate
  future addition, explicitly not built now — flagged as its own
  distinctly-named case if ever wanted, not folded into the existing loop.
  Verified two ways, including an isolated 40/40-clean-request test proving
  the "non-event" claim rather than trusting it by analogy.
- **Kafka's `external_confirm_s` root cause** (carried over from an earlier
  session's open item). Scoped as an explicitly bounded, low-priority
  investigation — two ordered candidates from a prior session
  (ISR catch-up lag, then GC-pause noise), both refuted with direct evidence.
  Approved one further bounded round given how closely the remaining
  unchased lead (`AdminClient` retry/backoff) matched this investigation's
  own already-proven bug pattern (test-harness cost wearing a Kafka-mechanism
  costume, found twice already in this same thread) — confirmed and
  localized precisely to a stalled `ListPartitionReassignments` RPC,
  reproduced across two independent trials with different controllers.
  Investigation closed at three candidates as scoped.

## Done — CI port-conflict incident

- Two screenshots showed the new E2E workflow failing at its pre-flight
  step — ports already occupied. Correctly diagnosed as the pre-flight
  check working as designed (a leftover manual-verification stack from
  earlier the same day), not a new bug.
- Reviewed a near-miss handled well: while re-triggering the workflow,
  Claude Code nearly issued a manual `docker compose up` against the exact
  stack a just-triggered CI run was actively using — caught via `gh run
  view` before anything destructive happened, named explicitly as a new
  standing risk specific to this Mac's dual duty as dev machine + always-on
  runner.
- Approved a `preflight-ci-check.sh` diagnosability improvement (cross-
  referencing `docker ps` since `lsof` on macOS always attributes Docker
  Desktop's published ports to its own proxy process, never the real
  container) and a `CLAUDE.md` CI-section staleness fix found along the way.

## Open, as of end of day

- k8s Kafka HA follow-up slice — still unscoped at this point in the day
  (this is what the next session, 2026-09-06, picks up).
- Cloud-deployment scope decision — parked behind the above.
- Circuit-breaker thread-pool load test under sustained concurrent failure
  — scoped earlier, not started.
- The `ListPartitionReassignments`-stalls-on-a-fresh-controller mechanism
  — named as a one-level-deeper, unchased follow-up, explicitly out of
  scope for the bounded investigation that found it.

## Next

1. Scope the k8s Kafka HA follow-up slice (design check-in first, per
   `CLAUDE.md`'s convention for structural choices) — see
   `status/claude_chat_2026-09-06.md` for what actually happened.
2. Revisit the cloud-deployment decision once that slice lands.
