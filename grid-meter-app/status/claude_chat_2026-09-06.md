# grid-meter-app — Status: 2026-09-06 (Claude Chat)

**Provenance note**: this file replaces an earlier `claude_chat_2026-09-05.md`,
which turned out to be misdated — it merged 2026-09-04's work with this day's
k8s Kafka HA work into one narrative, self-labeled 09-05 without checking
against git. No commits exist for 2026-09-05 at all; that date was a false
memory, not a real gap in work. Corrected via direct git log review (commits
`139689c`, `bbc08b4`, `2d07cdd`, all Sun Sep 6). Full mechanism detail lives
in `status/claude_code_2026-09-06.md`; this file covers the Chat-side design
review and decisions layered on top of that work.

## Done — k8s Kafka HA follow-up slice, scoped and closed in one session

- **Investigated existing scoping before designing anything fresh.** The
  thread name ("k8s Kafka HA follow-up slice, 3-broker StatefulSet in
  `kind`") had been carried in status logs since 2026-08-27 with no
  supporting doc ever reviewed. Traced it to its actual source,
  `k8s-terraform-decisions-2026-08-19.md`, which confirmed the current
  `kind` first slice deliberately shipped Kafka as a single broker — this
  was genuinely unscoped follow-up work, not something that had quietly
  moved elsewhere.
- **Explicit user framing carried through the whole design**: this work is
  partly about building real `kind`/`StatefulSet` fluency, not just landing
  working manifests — reflects the same "startup single-instance → corporate
  siloed → wanting to actually understand clustering" arc discussed earlier
  in this project. Asked Claude Code to explain *why* each design choice
  works the way it does in `kind` specifically, not just what to write.
- **Design-first check-in, per `CLAUDE.md`'s convention** — four questions
  posed before any manifest work: storage (ephemeral, matching the existing
  slice's own precedent — not reopened), the KRaft quorum-voter mechanism
  (the genuinely hard part), whether the app's own k8s config needed
  updating (the exact "chaos-tested infra ≠ protected app" lesson, checked
  proactively this time rather than found after the fact), and what "done"
  looks like (a `kind`-native equivalent of `kafka-ha-demo.sh` — a real kill
  test, not just pods reaching `Running`).
- **Reviewed Claude Code's design proposal in full before approving a build.**
  Notably good explanation, called out specifically: why a `StatefulSet` and
  not a `Deployment` with `replicas: 3` (a Deployment has no concept of "the
  second replica" — no stable identity to build a quorum voter list from,
  which a `StatefulSet` + headless Service exists specifically to solve);
  why `KAFKA_NODE_ID` needs a small startup-command wrapper
  (`${HOSTNAME##*-}`) while `KAFKA_ADVERTISED_LISTENERS` and the voter list
  are pure manifest templating; and the underlying general pattern worth
  keeping for future `kind` work — name-based addressing backed by a
  headless Service's stable DNS, not IP-based, is the general answer to "how
  do stateful peers find each other in k8s," not a Kafka-specific trick.
  Approved 0-indexed node IDs over forcing cosmetic parity with Compose's
  1-indexing (simpler, no correctness reason to match).
- **Approved dropping the redundant plain (load-balancing) `kafka` Service**
  entirely once building started — a load-balancing Service in front of 3
  KRaft brokers would have implied a client could talk to any one
  transparently, which isn't how the protocol works. This was flagged back
  to the user as a correctness fix, not just tidying.
- **Sign-off to build included one addition to the validation bar**: beyond
  the standard CRUD-through-the-real-topology check, explicitly required
  killing a live pod (`kubectl delete pod kafka-1`) under real continuous
  traffic and confirming both same-identity recovery and zero request
  failures — the actual `kind`-native equivalent of `kafka-ha-demo.sh`.
- **Two pre-existing, Kafka-unrelated Redis bugs surfaced and were reviewed
  as they were found**, not after the fact: k8s's Redis had never been
  updated after the app's Sentinel cutover landed in the code (crash-looping
  against a Sentinel address that never existed in k8s — nobody had run the
  full app in `kind` since that code change), fixed as an explicitly-labeled
  stopgap (`SPRING_PROFILES_ACTIVE=test`); and a second, independent bug
  (`SPRING_REDIS_HOST`/`PORT` — pre-Spring-Boot-3 property names silently
  binding to nothing) found and fixed in the same investigation. Noted
  approvingly that a self-caught verification mistake during this
  investigation (trusting clean-looking pod logs instead of directly
  checking `env | grep` inside the container, then catching that the first
  "fix" hadn't actually been wired in) is the same "clean result ≠ verified
  result" discipline this project has hit and caught several times before.
- **Validation reviewed and confirmed solid**: real CRUD through the actual
  3-broker topology, then the kill test — 80/80 real `POST /readings`
  requests succeeded across the full kill-and-recovery window,
  `kafka-1` confirmed returning with the same pod identity, all 81 readings
  confirmed landed in Postgres via a direct row count (not just trusted from
  HTTP 201s), full ISR restored after recovery.
- **Closing checklist sent and confirmed complete this same session** (this
  was the open question the misdated 09-05 file had flagged as unconfirmed):
  the `SPRING_PROFILES_ACTIVE=test` stopgap's labeling was reworded from
  "not a real fix" to a real, intentional setting now that it's live-verified
  and wired in properly; `k8s/README.md` gained a Redis entry in its
  "Deliberate simplifications" section, alongside the existing ephemeral-
  storage one; and `docs/ha-scope.md` gained a new "Revisit triggers" entry
  for a k8s Redis Sentinel HA follow-up — recorded there specifically
  because the Kafka slice itself sat as an easy-to-lose "revisit later" item
  for weeks before actually getting picked up, and the intent is that the
  Redis one doesn't disappear the same way.

## Correction issued this session

- The earlier `claude_chat_2026-09-05.md` was identified as misdated —
  written from Chat's own unverified recollection with no git access to
  check against, it merged this day's work with 2026-09-04's into one
  false "long session before the long weekend" narrative. Corrected once
  Claude Code checked actual git history and found no 2026-09-05 commits
  exist at all. This file and `claude_chat_2026-09-04.md` replace it: the
  09-05 file was deleted by the user rather than kept with a correction
  note, given clean replacements were being written anyway.
- Worth naming plainly as a limitation, not glossed over: Claude Chat has
  no persistent memory across sessions and no git access, so a status claim
  written from chat transcript alone — however well-hedged — is not the
  same as a claim checked against the one source of truth that doesn't
  drift. The original file's own disclaimer ("not independently
  re-verified") was the right instinct but not a substitute for the actual
  check.

## Open

- **k8s Redis Sentinel HA follow-up** — genuinely scoped as future work
  this session specifically so it doesn't sit dormant the way the k8s
  Kafka HA slice itself did; tracked in `docs/ha-scope.md`'s "Revisit
  triggers" section, not yet started.
- **Cloud-deployment scope decision** — its stated blocker (k8s Kafka HA)
  is now done, but the newly-found k8s Redis gap raises the question of
  whether that should close first too, since `cloud-deployment-scope.md`'s
  own Kafka-manifest-reuse language implicitly assumes a complete, correct
  `k8s/` first. Still the user's call.
- **k8s Kafka `StatefulSet` design rationale as a standalone doc** — the
  "why StatefulSet, not Deployment" reasoning and the `KAFKA_NODE_ID`/
  `KAFKA_ADVERTISED_LISTENERS` mechanics currently exist only in chat
  transcript, unlike every other HA investigation in this project, which
  got a durable `*-ha-scope.md` doc. Raised with the user as worth writing
  up (a `k8s-kafka-ha-scope.md` sibling), not yet actioned.
- Carried forward, untouched: circuit-breaker thread-pool load test under
  sustained concurrent failure; the full-Patroni-cluster-outage
  `chaos-demo.sh` case; the `ListPartitionReassignments`-stalls-on-a-fresh-
  controller mechanism question.

## Next

1. Decide whether to write `k8s-kafka-ha-scope.md` now.
2. Revisit the cloud-deployment decision, factoring in the new k8s Redis
   gap.
3. Decide whether to scope the k8s Redis Sentinel HA follow-up next, or
   pick a different open thread.
