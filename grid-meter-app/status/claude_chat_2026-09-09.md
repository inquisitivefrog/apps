# grid-meter-app — Status: 2026-09-09 (Claude Chat)

Confirmed against real commit timestamps (`ef8a2e7`, `08d244b` at
17:00 -0700). Short session on the Chat side — the design brief only; the
build, first three bug fixes, and first validation pass are Claude Code's
own same-day work, documented in `status/claude_code_2026-09-09.md`.
Continuation from `claude_chat_2026-09-08.md`.

## Done

- **k8s Redis Sentinel HA — design brief.** Mirroring the Kafka slice's
  own check-in process: confirmed two independent `StatefulSet`s +
  headless Services (Redis data nodes, Sentinels — not one combined
  resource, since they're separate peer groups with separate identity
  needs), ephemeral storage, 0-indexed naming, reuse-over-rewrite for
  `scripts/redis-entrypoint.sh` (parameterized for k8s rather than
  forked), same kill-test validation bar as Kafka. User confirmed all
  four design points directly and asked for a concrete task brief for
  Claude Code rather than a formal pre-build doc, trusting drift
  correction after the fact over blocking on more design review up
  front — consistent with this project's general practice of favoring
  forward progress with honest correction over exhaustive up-front
  design.
  - Flagged two things for Claude Code to verify rather than trust as
    written: the `redis-entrypoint.sh` hardcoded `SENTINEL_HOSTS`/
    `MY_HOSTNAME` values needed to become parameters (not a fork), and
    the proposed `SPRING_DATA_REDIS_SENTINEL_*` env var names were a
    guess, to be confirmed against the real Spring binding before use.
    (Confirmed wrong in the actual build — real property is
    `SPRING_REDIS_SENTINEL_*`.)

- **Build, first fix, first validation — Claude Code's own same-day
  session, see `status/claude_code_2026-09-09.md` for full detail.**
  Headline items: the `StatefulSet` port itself (`k8s/redis.yaml` +
  new `k8s/sentinel.yaml`); a genuine mid-session disk crisis (6GB →
  8.2GB free, root-caused as *not* primarily Docker this time —
  `Docker.raw` was only 17GB, unlike prior August incidents; user freed
  space to 30GB independently); a real split-brain bug found via Claude
  Code's own proactive Compose Stage 4 re-run (not yet reviewed by Chat
  at this point); a three-part fix (`failover_in_progress` flag check →
  IP-vs-hostname matching → strict clean-`"master"`-flags requirement,
  widened to 60 attempts); a first `docs/k8s-redis-ha-scope.md` write;
  and a first validation pass (`RTO 7s`, `SPLIT-BRAIN: NO` under
  `caffeinate`). Committed `ef8a2e7`, `08d244b`.

## Open

- **09-09's Redis HA work had not yet been reviewed by Claude Chat as of
  end of day** — per `status/claude_code_2026-09-09.md`'s own "Open"
  section. That review, and what it found, is covered in
  `claude_chat_2026-09-10.md`.

## Next

- Claude Chat reviews the finished 09-09 Redis Sentinel work — see
  `claude_chat_2026-09-10.md`.
