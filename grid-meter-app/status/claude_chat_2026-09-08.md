# grid-meter-app — Status: 2026-09-08 (Claude Chat)

Confirmed against real commit timestamps (`b248a70`, `58edea5`, `118adeb`
at 17:05-17:06 -0700; `5ce9c24` at 21:28 -0700), correcting an earlier guess
that placed this work on 09-09. Continuation from `claude_chat_2026-09-06.md`.

## Done

- **Cluster-health check on resume**: after `docker start
  grid-meter-control-plane` (idle 2 days), `api` pods showed `0/1 Running`
  with repeated restarts — diagnosed as the known cold-start
  dependency-race (readiness catching up to a Postgres/Kafka restart lag),
  confirmed self-healing within ~2 minutes; `local-path-provisioner`'s
  `Error` state was a red herring (unused — this project has no PVCs).

- **`docs/k8s-kafka-ha-scope.md` — drafted, then live re-verified against
  a real restarted cluster, not just the 09-06 session that produced the
  design.** Draft covered the `StatefulSet`-vs-`Deployment` reasoning, the
  `KAFKA_NODE_ID` shell-wrapper vs. pure-templating distinction, the
  dropped redundant load-balancing Service, and the two unrelated Redis
  bugs found during the original 09-06 build. Re-verification: 27/27
  requests succeeded through a `kubectl delete pod kafka-1` window,
  correct row count, full ISR restored. **A real measurement bug was
  caught along the way**: the first recovery-time check reported an
  implausible "0s" — root cause was a `Running`/`Ready` check trusting a
  stale signal (the old pod still reporting ready during its own
  graceful-termination window). Rekeyed off pod UID change instead of
  status flags; corrected figure ~2.44s. Documented honestly in the doc,
  not smoothed over.

- **Doc-correction sweep across seven HA/testing docs**, same session:
  `autoscaling-scope.md` still described Kafka as single-broker RF=1;
  `k8s-terraform-decisions...` still framed k8s Kafka as single-broker
  after the 09-06 StatefulSet migration; `observability-taxonomy.md`
  still called the circuit breaker unbuilt after it shipped 09-04;
  `redis-ha-scope.md`'s Lettuce/Kafka-retry theory was never
  independently isolated and has since been refuted;
  `resilience-scope.md`'s circuit-breaker test-plan bullets predated the
  breaker actually being built; `testing-strategy.md` still deferred an
  E2E tier that now exists and runs on a self-hosted runner;
  `postgres-ha-scope.md`'s closing banner date didn't reflect its own
  later edits. Documentation accuracy only, no behavior changes.

- **`claude_chat_2026-09-04.md`/`claude_chat_2026-09-06.md` added to
  `status/`** — the two status files reconstructed and corrected earlier
  in this thread, after the original misdated `claude_chat_2026-09-05.md`
  was deleted.

- **`DELETE /meters/{id}` on a meter with existing readings — found
  misreporting `503` instead of `409`, root-caused, and fixed.** Traced
  to the circuit-breaker work's `GlobalExceptionHandler` fix (09-03),
  which correctly claimed the `DataAccessException` hierarchy for real
  Postgres-outage cases but was also catching the unrelated
  `DataIntegrityViolationException` subtype (an ordinary FK-constraint
  rejection), misreporting a normal client action as an outage. Found
  while cleaning up test data during the `k8s-kafka-ha-scope.md`
  re-verification above — previously untested territory. Fixed with a
  dedicated `@ExceptionHandler(DataIntegrityViolationException.class)`
  mapped to `409`; Spring dispatches by nearest-match regardless of
  declaration order, so no reordering was needed elsewhere in the class.
  New regression test
  (`delete_meterWithExistingReadings_returns409NotServiceUnavailable`),
  80/80 green twice locally. Cross-referenced into `resilience-scope.md`'s
  standing lesson. Committed and pushed (`5ce9c24`).
  - CI flagged an unrelated flaky test (`ingest_sameIdempotencyKeyTwice`,
    Awaitility timeout) on the first push; passed clean on retry.
    Plausible cause (dual-duty runner contention — `kind` cluster and
    CI's own Testcontainers stack sharing the same Mac simultaneously)
    named but not independently confirmed via a proper before/after
    check. **Not formally closed** — see Open.

- **Laptop crash, later the same evening.** All work up to that point
  (`5ce9c24`, 21:28) was already pushed, so nothing was lost — confirmed
  after the fact via git log.

## Open

- **Flaky-test investigation (`ingest_sameIdempotencyKeyTwice`) — not
  formally closed.** Two clean local runs plus one green CI retry point
  toward "transient, likely dual-duty-runner contention," but the
  stronger before/after check (confirm the same test fails/passes
  independent of the `DELETE`-fix commit, on the prior commit too) was
  never done.

## Next

- Resume post-crash: confirm Docker Desktop/self-hosted runner/`kind`
  cluster all survived cleanly, confirm clean `git status`, then continue
  toward the k8s Redis Sentinel HA follow-up — see `claude_chat_2026-09-09.md`.
