# grid-meter-app — Status: 2026-08-11 (Claude Code)

Done:
- Restructured session status reporting: status is no longer appended inline
  to CLAUDE.md (which would grow unboundedly and dilute the standing
  instructions it's supposed to hold). Created `status/`, archived the two
  prior inline blocks as `status/claude_chat_2026-08-07.md` and
  `status/claude_chat_2026-08-10.md`, and left a short pointer in CLAUDE.md.
  Naming convention going forward: `claude_chat_<date>.md` for sessions run
  via Claude Chat, `claude_code_<date>.md` for sessions run via Claude Code.
- Verified `docker compose up -d` after a Docker Desktop restart — all 11
  services came back healthy, no lingering issues from the restart.
- Cleaned up Claude Code permissions: found the existing `.claude/
  settings.local.json` at the `apps/` git root was cluttered with brittle
  one-off literal entries (exact curl calls with hardcoded UUIDs, one-off
  echo strings) that wouldn't match future invocations. Ran the
  `fewer-permission-prompts` skill and created a new, **committed**
  `apps/.claude/settings.json` (repo-wide, applies to all Java apps in this
  monorepo, not just grid-meter-app) with 9 curated, safe patterns (`mvn
  test*`, `mvn -q -DskipTests*`, `mvn dependency:tree*`, `mvn
  help:effective-pom*`, `docker compose logs/ps/up -d/build *`).
  Deliberately did NOT allowlist `mvn *` or `docker compose *` broadly (both
  can execute arbitrary commands via specific goals/subcommands — `exec:*`/
  `antrun:run` for Maven, `exec`/`run` for Compose), nor `docker volume rm`/
  `docker compose down` (destructive), nor a `curl` localhost wildcard
  (transcripts mixed read-only GETs with data-mutating POSTs). Left
  `settings.local.json` (personal, gitignored) untouched.
- **Wrote the first real Testcontainers-backed component tests**, per
  docs/testing-strategy.md's planned layering (Testcontainers blocker was
  resolved in the prior Claude Chat session):
  - `support/ComponentTestSupport.java` — shared base class starting real
    Postgres 18.4 / Kafka 4.3.1 / Redis 8.10 (via GenericContainer — no
    official Testcontainers Redis module exists) once per JVM run via a
    static initializer (the "singleton container" pattern), not
    `@Testcontainers`/`@Container`, since that annotation pair would tear
    the container down after the first test class and break the next one.
  - `MeterComponentTest` (8 tests) — create/find/search/update/delete
    against real Postgres, including the unique-serial-number constraint
    (a real DB-level check a mocked test can't catch).
  - `ReadingComponentTest` (6 tests) — the full async path: ingest →
    Kafka → `ReadingEventConsumer` → Postgres write + Redis cache, polled
    with Awaitility (added as a new test dependency, v4.3.0, verified
    current on Maven Central) rather than `Thread.sleep`. Deliberately does
    NOT test PUT-rejection — that's an HTTP-level (405) concern for the
    future REST Assured API test layer, out of scope for this
    service-level component suite.
  - `mvn test`: 15 new tests + the existing smoke test, all green, exit 0.
- **Found and fixed a real production bug via the new tests**: `RedisConfig`'s
  `GenericJacksonJsonRedisSerializer` never enabled default typing, so any
  read through the generic `RedisTemplate<String, Object>` silently
  deserialized as a raw `LinkedHashMap` instead of its real class — a
  `ClassCastException` waiting to happen in real usage, not just in the
  test. Fixed with `enableDefaultTyping()` scoped to a
  `BasicPolymorphicTypeValidator` trusting only `com.gridmeter.api.reading`
  + `BigDecimal`, mirroring the existing Kafka `spring.json.trusted.packages`
  trust boundary, instead of the unsafe blanket-typing option.
  - Side discovery while chasing this: Spring Boot 4.1 runs **two Jackson
    generations side by side** on this classpath — the classic
    `com.fasterxml.jackson` 2.21.4 line (our explicit `jackson-databind`
    dependency) and a newer `tools.jackson` 3.1.4 line (pulled in
    transitively via `spring-boot-jackson` for some newer Spring
    integrations, including this Redis serializer). Not currently causing
    problems elsewhere, but worth remembering if a future Jackson-related
    error references an unfamiliar package.

Open:
- frontend/ still a placeholder — routing (single view vs React Router) and
  styling (plain CSS / Tailwind / component library) still undecided.
- No CI pipeline exists yet at all. testing-strategy.md's planned wiring
  (unit + component tests block merge every push) isn't set up — today's
  component tests only run locally via `mvn test` so far.
- REST Assured API test layer not started — that's where PUT
  `/readings/{id}` rejection (405) should get an explicit HTTP-level
  assertion, deferred from today's component tests.
- A fast, dependency-free unit test for `PaginationProperties` clamping
  (default 20 / max 100) would be cheap and valuable — not yet written,
  belongs in the unit tier rather than this component suite.
- `settings.local.json` (personal) still has its old one-off literal
  entries from before today's cleanup — harmless, just superseded by the
  new patterns in the shared `settings.json`; not actively pruned.
- Carried over from 2026-08-10, still open: Mockito self-attach deprecation
  warning, Netty macOS DNS resolver warning — cosmetic, not blocking.

Next:
- Wire unit + component tests into a real CI pipeline (GitHub Actions),
  per testing-strategy.md's "blocks merge on failure" plan — natural
  next step now that real component tests exist to run.
- Or: scaffold frontend (Vite + React + TanStack Query) once
  routing/styling decisions are made.
- Consider the `PaginationProperties` unit test and the REST Assured
  PUT-rejection test as smaller, cheap follow-ups either way.
