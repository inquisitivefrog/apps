# grid-meter-app — Status: 2026-09-10 (Claude Chat)

Covers only Claude Chat's review-and-harden pass over the k8s Redis
Sentinel HA work Claude Code designed, built, first-fixed, and first
validated the previous day — see `claude_chat_2026-09-09.md` and
`status/claude_code_2026-09-09.md` for that work. This file starts where
those left off: `status/claude_code_2026-09-09.md`'s own "Open" section
states Chat had not yet reviewed the finished work at end of that day.
Ends with both local HA tracks (Kafka and Redis) fully closed and the
vendor-bug-report bookkeeping current. Cloud-deployment scoping is next.

## Done

- **k8s Redis Sentinel HA — Chat's review pass, 2026-09-10.** the finished script against what had actually been fixed
    raised two real, checkable questions rather than accepting "fixed" at
    face value: was the bug genuinely pre-existing, or introduced by the
    k8s parameterization itself; and was it a real cross-Sentinel quorum
    race, or just one Sentinel's own internal state lagging.
  - **Confirmed pre-existing, not introduced by the parameterization**:
    Claude Code reproduced the identical mechanism against the
    pre-parameterization script as a negative control — latent since the
    original Finding A design (2026-08-28).
  - **Confirmed as a genuine quorum-vs-single-responder race**, not
    single-Sentinel lag: cross-referenced all 3 Sentinels' logs from the
    original 09-09 reproduction — the elected failover leader (the one
    actually driving reconfiguration) lagged 6.25s behind the two passive
    followers in reaching its own `+switch-master` state. The original
    entrypoint trusted whichever Sentinel answered first, with no
    cross-check — a structural gap the fix already closed as a side
    effect, but not yet *proven* against this exact scenario.
  - **A file-version discrepancy surfaced and resolved during review**: a
    `redis-entrypoint.sh` shared with Chat for review turned out to be a
    stale, pre-fix snapshot (most likely captured during the negative-
    control swap) — Claude Code confirmed the real on-disk file already
    had the fix, and the discrepancy was provenance, not a real gap.
  - **The existing verification was judged too weak and redone**: only 1
    of 5 clean 09-09 runs had actually exercised the lagging-leader
    condition, and even that one was a smaller ~1s gap than the original
    6.25s finding. A deliberate, harder reproduction was built instead.
    Result: `SPLIT-BRAIN: NO`, demoted at `t+0.13s`, zero window where the
    restarted node ever claimed to be master — a direct, targeted proof
    against the exact original scenario, not a generic "the check exists"
    claim.
  - **A separate, honestly-flagged finding from that same run**: under
    real resource contention, all 3 Sentinels can stay dirty for the full
    60-attempt budget during a cold-bootstrap reset, falling through to
    the already-documented bare-start fallback — a named, accepted risk,
    not a bug, now observed live rather than only theorized.
  - `docs/k8s-redis-ha-scope.md` updated with this sharper, empirically-
    confirmed root cause and the negative-control evidence.
    `ha-scope.md`'s "Revisit triggers" entry closed and replaced with a
    small forward-looking note on the cold-bootstrap contention fallback;
    mirrored as a one-line comment next to `redis-entrypoint.sh`'s
    `max_attempts=60`.
  - **Final re-verification against a genuinely fresh cluster**: the
    (by now investigation-worn) `kind` cluster was deliberately torn down
    and rebuilt from scratch rather than trusted — clean
    `./k8s/deploy.sh`, full functional check (login → create meter →
    ingest reading → confirmed async Kafka→Postgres landing → confirmed
    the Redis cache write on the Sentinel-reported primary, correctly
    self-identified from a real cold bootstrap).
  - Committed and pushed across several commits (`197c1a8`, `78c70b7`,
    `48e479f`).

- **Vendor-bug-report bookkeeping brought current.** Found via a direct
  check (prompted by the process doc's own "don't let the two drift out
  of sync" rule): `load-tests/vendor-bug-reports/redis/NOTES.md` hadn't
  been updated since the original 09-02 Stage 6 close-out, despite this
  session generating ~15 new evidence run directories for the k8s
  follow-up. Added a run index pointing at `k8s-redis-ha-scope.md` as
  the authoritative narrative (index, don't duplicate — matching the
  file's existing convention). `docs/vendor-bug-report-process.md`'s
  status-table date/note updated. The conclusion itself never changed —
  all 3 k8s Redis bugs found this session are confirmed to live in this
  project's own `redis-entrypoint.sh`, not in Redis/Sentinel itself, so
  Redis is still not a vendor-bug candidate. Committed and pushed
  (`9e8aa32`).
  - **One unresolved thread**: whether the status table's date was
    genuinely stale (09-04) before this fix, or already read 09-10 —
    flagged to double-check against the actual pre-edit file content;
    doesn't change the substantive fix (the missing NOTES.md run index),
    only whether the date-staleness framing in the commit message is
    accurate.

## Open

- **Flaky-test investigation (`ingest_sameIdempotencyKeyTwice`) — not
  formally closed.** Two clean local runs plus one green CI retry point
  toward "transient, likely dual-duty-runner contention," but the
  stronger before/after check (confirm the same test fails/passes
  independent of the `DELETE`-fix commit, on the prior commit too) was
  never done. Worth a short note in `testing-strategy.md`'s flaky-test
  tracking (or a comment near the test) naming dual-duty contention as
  the leading suspect, so a recurrence has a documented starting point.
- **A possible second instance of "sleep-across-suspend corrupts a
  timing measurement"** worth naming as its own pattern in
  `testing-strategy.md`, alongside the pod-UID/readiness-flag entries
  already there — the k8s Redis kill test's bogus "1033s" figure (caused
  by the laptop sleeping mid-background-poll, resuming with a `date +%s`
  delta reflecting real suspended wall-clock time) is a second,
  independent occurrence of a distinct failure shape from the fixed-sleep-
  races-readiness pattern already documented. Raised, not yet written up.
- **Vendor-bug-report-process.md date-staleness claim** — worth a quick
  confirm (see above), low priority, doesn't change the real fix.
- **Cloud-deployment scope decision** — the actual next thread. Both
  local HA tracks (Kafka, Redis) are now fully closed and StatefulSet-
  ported to `kind`, matching Compose. `cloud-deployment-scope.md` (last
  touched 2026-08-27) needs a fresh read-through before any Terraform
  work starts, specifically to confirm its assumption of reusing the k8s
  manifests directly still holds now that both Kafka and Redis carry
  specific headless-DNS/entrypoint-script wiring that didn't exist when
  that doc was written.
- Carried forward, untouched this session: circuit-breaker concurrent-
  load test (thread-pool protection under sustained failure), trend
  alerts (scoped, not designed), the `ListPartitionReassignments`-stalls
  mechanism (named, not chased further), the unfiled Kafka KRaft JIRA
  report (evidence-ready, pending account approval).

## Next

1. Re-read `cloud-deployment-scope.md` in full before any Terraform work
   starts — confirm the manifest-reuse assumption still holds against
   the now-more-complex Kafka/Redis StatefulSet wiring; treat this as a
   gating sanity check, not a re-scoping.
2. Draft AWS-first design check-in questions (same shape as the Kafka
   and Redis k8s design sessions) once that read-through is done.
3. Decide whether to formally close the flaky-test investigation with a
   real before/after check, or accept the current evidence and just
   document the leading suspect.
4. Optionally: write up the sleep-across-suspend timing-measurement
   pattern in `testing-strategy.md` as its own named entry.
