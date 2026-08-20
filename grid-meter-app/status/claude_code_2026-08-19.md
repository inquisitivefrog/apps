# grid-meter-app — Status: 2026-08-19 (Claude Code)

Done:

- **Recovered from an interrupted prior session**: the user had been
  building `api/bruno/` with Claude Code when the machine ran out of disk
  space, forcing a reboot. Verified disk space was actually clear (2.4Gi
  free) and read every one of the 23 `.bru`/config/doc files already on
  disk to confirm none were corrupted or truncated by the crash — all were
  complete and well-formed, so no work was lost. (`6efc91d` is unrelated —
  see below — this recovery itself produced no commit, just confirmation.)

- **Committed `docs/k8s-terraform-decisions-2026-08-19.md`**, which existed
  untracked from an earlier Claude Chat session relayed to the user before
  this session started: Terraform is explicitly out of scope (no real
  cloud target to provision anywhere in this project), and the `kind` demo's
  first slice goes full in-cluster (api, frontend, postgres, kafka, redis +
  Traefik IngressRoute) rather than depending on the host Compose stack for
  the data tier, so `kind create cluster` + `kubectl apply -f k8s/` is
  fully self-contained. Observability wiring is deferred to a follow-up
  slice. (`6efc91d`)

- **Finished and validated `api/bruno/`** — the manual/exploratory API test
  collection named in `testing-strategy.md` since it was written but never
  built, closing the last item from that doc's planned tooling. Structure:
  `auth/` (login, invalid-credentials anti-enumeration check, an explicit
  unauthenticated-request check) → `meters/` (create/search/get/update) →
  `readings/` (ingest/search/get/reject-put-405) → `ops/`
  (health/prometheus, the two unauthenticated routes) → `cleanup/`
  (delete-reading, delete-meter).
  - User suggested installing the real Bruno CLI (`npm install -g
    @usebruno/cli`) rather than trusting the collection by inspection
    alone. Installed it (4.0.0) and ran `bru run --env local` against the
    live `docker compose` stack.
  - **First run failed — a real bug, not a fluke**: 3 of 15 requests
    failed. Root cause: Bruno executes folders as whole units in `seq`
    order, so `Delete Meter` (originally the last request inside the
    `meters/` folder) ran to completion before the `readings/` folder ever
    started, deleting the meter the `meterId` variable pointed at and
    cascading into a 404 on Ingest Reading and 400s on everything after it
    in `readings/`. The collection's own README had a caveat about deleting
    a meter with existing readings hitting an FK constraint — that's a
    different failure mode than what actually happened, so the caveat
    didn't prevent this.
  - Fixed by moving `Delete Meter` and `Delete Reading` out of their
    resource folders into a new `cleanup/` folder that runs last (seq 5),
    after auth/meters/readings/ops. Re-ran: **15/15 requests, 27/27
    assertions, all green.**
  - Also wrote `scripts/verify-bruno-collection.sh` — a curl-based replay
    of the identical request sequence, for headless verification on a
    machine without the Bruno CLI/GUI installed (matches the existing
    `verify-auth-security.sh` pattern in the same directory). Ran clean
    both before and after the folder fix (it happened not to hit the
    ordering bug, since it was written as one flat top-to-bottom script
    rather than mirroring Bruno's per-folder execution model — the real
    `bru run` is what actually caught the bug).
  - Docs: `api/bruno/README.md` rewritten to describe the 5-folder
    structure and explain why `cleanup/` exists as its own folder;
    `scripts/README.md` indexed the new script; `tech-stack-versions.md`
    gained a row pinning Bruno CLI 4.0.0 (host-native like JMeter — not a
    project dependency, no `package.json` entry). (`2c6ea9c`)

- Both commits pushed to `origin/main` (direct push, bypassing the two
  required status checks as this repo's solo-owner — same behavior
  documented as intentional back in the 2026-08-11 session).

**Second phase — k8s `kind` first slice.** Everything below is **on disk,
uncommitted** (see the file list in "Open" below) — nothing lost across a
normal reboot, since these are all real files on disk, not in-memory
state; the disk-full incident from earlier in this session is a different
failure mode (see the blocker at the top of Open).

- Applied both `docs/architecture.md` doc edits specified in
  `docs/k8s-terraform-decisions-2026-08-19.md`: the `kind` bullet in
  "Deployment model" now describes the full-in-cluster first slice, and a
  new "Terraform — explicitly out of scope" subsection was added.
- Asked the user to resolve the one implementation detail the decision doc
  left open (how the demo reaches Traefik from the browser) rather than
  guessing: **kind port mapping** was chosen over `kubectl port-forward`,
  so `http://localhost/...` works identically to Docker Compose with no
  extra terminal/command needed once the cluster is up.
- **Scaffolded `k8s/`** — `kind-config.yaml` (port-80 mapping +
  `ingress-ready=true` node label), `configmap.yaml`/`secret.yaml`
  (non-secret env vars vs. dev-only hardcoded credentials, mirroring
  `docker-compose.yml`'s api/postgres env blocks), `postgres.yaml`/
  `kafka.yaml`/`redis.yaml` (Deployment + Service each, no PVCs — ephemeral
  by design, matching the decision doc), `api.yaml` (2 replicas, matching
  Compose's `--scale api=2` story, readiness/liveness probes on
  `/actuator/health`), `frontend.yaml`, `traefik.yaml` (the controller
  itself — `--providers.kubernetescrd` in place of Compose's
  `--providers.docker`, `hostPort`/`nodeSelector`/toleration for the kind
  port-mapping trick), `ingressroute.yaml` (same path-based split and
  priorities as Compose's Traefik router labels), plus `deploy.sh`/
  `teardown.sh` convenience scripts and a `README.md` documenting
  prerequisites, apply order (and *why* it matters — CRDs before the
  `IngressRoute` that needs them), the port-mapping mechanism, and
  deliberate simplifications.
- **Vendored Traefik's official v3.7 CRD + RBAC manifests** rather than
  writing them from memory (a ~4600-line OpenAPI schema is exactly the
  kind of thing that's easy to get subtly wrong from recall) or leaving
  `kubectl apply -f k8s/` dependent on a live URL at demo time. Per repeated
  user feedback this session to script multi-step/non-trivial commands
  instead of firing off compound one-liners, wrote
  `scripts/fetch-traefik-k8s-manifests.sh` first and ran that, rather than
  a raw `curl` sequence — produced `k8s/traefik-crds.yaml` (4601 lines) and
  `k8s/traefik-rbac.yaml`.
- **Claude Chat reviewed the plan before validation** and flagged three
  things worth double-checking: Kafka's advertised listeners actually
  matching k8s Service DNS (not just copied from Compose), Traefik not
  being silently assumed present in a bare `kind` cluster, and the Secret
  manifest not quietly normalizing hardcoded plaintext credentials as fine
  without comment. Checked all three against the actual files: the first
  two were already correct (verified, not just asserted), the third was a
  real documentation gap — added a "Secret management: what's real here
  vs. what a production setup needs" section to `k8s/README.md` naming
  concrete alternatives (External Secrets Operator, Sealed Secrets, Vault
  Agent Injector).
- Wrote `scripts/check-port-80.sh` (another script-first response to user
  feedback, this time before even proposing to check port availability
  inline) and used it to confirm Docker Compose's Traefik was still
  holding host port 80 from the Bruno-collection work earlier in the
  session — would have silently conflicted with kind's port mapping.
  Explicitly asked before running `docker compose down` (a request the
  user initially declined, then handled themselves and confirmed back).

**Blocker resolved, k8s slice validated end-to-end (post-reboot).**

- After the reboot, Docker Desktop came back healthy (`docker info`
  responded instantly). Root cause of the earlier disk-full/unresponsive
  daemon was never conclusively pinned to licensing vs. disk pressure
  specifically — but `docker system df` showed 21.27GB of build cache +
  12.18GB of dangling images + 15.55GB across 320 unused volumes sitting
  reclaimable, and host free space was down to 4.7Gi. User chose to prune
  all three (`docker builder prune -f && docker image prune -f && docker
  volume prune -f`, 320 volumes included after confirming the risk of
  touching other projects' data) rather than risk repeating the crash on
  retry — freed disk back up to 38Gi.
- The user's first `kind create cluster --name grid-meter` (no `--config`
  flag, run directly in their own terminal while troubleshooting) produced
  a cluster missing both things `k8s/traefik.yaml` depends on: the
  `ingress-ready=true` node label and the port-80 host mapping. Caught by
  checking `kubectl get node --show-labels` and `docker ps` port mappings
  before deploying anything onto it, rather than assuming the cluster
  matched `kind-config.yaml` just because `kind create cluster` succeeded.
  User deleted and recreated with `--config k8s/kind-config.yaml`;
  re-verified both were present this time before proceeding.
- `./k8s/deploy.sh` ran clean end-to-end: both images built, cluster
  reused, CRDs/RBAC/Traefik/data-tier/api/frontend/IngressRoute all
  applied in order, every rollout succeeded (`api`'s 2/2 replicas
  included).
- **Full validation, both at the API layer and through the real browser
  UI** (Chrome extension needed a first-time install — walked the user
  through `https://claude.com/claude-in-chrome` → enable in
  `chrome://extensions` → sign into the same claude.ai account — before it
  would connect):
  - API-level (`curl`): login → create meter (201) → ingest reading (201,
    confirmed flowing through Kafka → consumer → Postgres/Redis by
    immediately finding it via search) → search by `meterId` → `PUT
    /readings/{id}` correctly rejected with 405 → delete reading → delete
    meter (204s). One false alarm along the way: an unquoted UUID
    interpolated into a shell-built JSON body (`"meterId":$METER_ID`
    instead of `"meterId":"$METER_ID"`) produced invalid JSON and a 400 —
    a bug in the ad hoc test script, not the app; fixed and re-ran clean.
  - Browser-level: login redirect works (`ProtectedRoute` gate), New
    Meter dialog's Create button correctly stays disabled until required
    fields are filled, created meter appears in the table and on the
    detail page, Readings page renders read-only with no create/edit
    affordance (matches the immutability principle).
  - **Real (non-blocking) bug found in the browser walkthrough**: the
    Meters table displays "Installed" one day earlier than what was
    entered (`01/01/2026` in → `12/31/2025` shown), while the same value
    reads back correctly as `01/01/2026` in the detail page's edit form —
    isolated to `MetersPage`'s read-only date formatting, most likely a
    UTC-parsed-then-local-rendered date-only value. Not yet filed as a
    GitHub issue or fixed — flagged here for follow-up.
  - **Apparent bug that wasn't one**: user reported `/readings` and
    `/meters/:id` "not resolving" while `/login` and `/meters` did.
    Reproduced directly — a hard navigation (typing the URL, not clicking
    an in-app link) to *either* `/meters` or `/readings` after logging in
    bounces back to `/login`, identically. This is the documented
    in-memory-token design working as intended (`architecture.md`:
    "a hard browser refresh drops the session and requires re-login") —
    the user's `/meters` success was from clicking the nav link
    client-side (token stays alive), not from typing the URL fresh. Not a
    route-specific bug; explained to the user how to test sub-routes
    without tripping over this (log in once, then navigate via clicks).
  - Confirmed `/actuator/health` and `/actuator/prometheus` both reachable
    unauthenticated with real data (Micrometer metrics, HikariCP pool
    stats) directly from the user's own browser, independent of my
    `curl` checks.
- Wrote `docs/identity.md` — a new supplementary doc (separate from
  `architecture.md`'s existing Authentication section) capturing why port
  443/TLS is deliberately not part of this stack: the JWT design is
  already stateless-bearer-header specifically to avoid cookie/CSRF
  machinery, and everything here runs locally (Compose/`kind`), so there's
  no real network path for TLS to protect against — same "no real target
  to justify the infrastructure" reasoning already applied to ruling
  Terraform out of scope. Revisit only if real external deployment is ever
  added to scope.
- Tightened `docs/k8s-terraform-decisions-2026-08-19.md`'s scope section
  after Claude Chat flagged that it listed only "Traefik IngressRoute" in
  the concrete-scope bullets, which reads as CRD-only and doesn't say the
  Traefik *controller* itself needs installing into a bare `kind` cluster
  (no edge proxy by default, unlike Compose). The actual `k8s/` build
  already did this correctly (`traefik.yaml` + vendored CRDs/RBAC) — this
  was a documentation-only gap, not an implementation one, but worth
  fixing so the doc doesn't mislead a future reader.
- Wrote `scripts/delete-meter.sh <meter-id> [base-url]` — logs in with the
  seed demo credentials, deletes any readings for that meter first (avoids
  the FK-constraint issue noted in `api/bruno/README.md`), then deletes
  the meter. Written on request rather than retyping the compound curl
  cleanup chain each time; used to clean up the UI-created test meter
  after validation.
- Cleaned up: both test meters created during validation (one via `curl`,
  one via the browser UI) were deleted afterward, leaving the `kind`
  cluster's data tier empty.
- Committed as two commits (docs separate from implementation, matching
  today's earlier Bruno-work pattern) and **pushed to `origin/main`**
  (`5c07d1f` docs, `27a080e` the k8s slice itself — direct push, bypassing
  the two required status checks as this repo's solo-owner, same
  documented-intentional behavior as prior sessions). First push attempt
  failed with an SSH `Permission denied (publickey)` — user had rebooted
  earlier in the session and forgotten to re-add their SSH key to the
  agent afterward; re-added it once flagged, retry succeeded immediately.

Open:

- **Real bug to fix, not yet done**: `MetersPage`'s "Installed" column
  displays a date one day earlier than what was actually stored (see
  above) — likely a date-only-value/timezone formatting bug. No GitHub
  issue filed yet (the issue-tracking convention itself — labels, template
  — is also still unbuilt, see below).
- `load-tests/` spike profile still not validated at its documented real
  scale (60s duration, 2 `api` replicas) — only a 15s single-replica smoke
  check has run (carried over from 2026-08-18).
- `load-tests/` CI's `schedule` trigger still hasn't fired for real
  (carried over from 2026-08-18).
- Frontend E2E tier (Playwright) — still explicitly deferred, no concrete
  need yet.
- `frontend-test` CI job still not a required branch-protection check.
- GitHub Issues bug-tracking setup (severity/component labels, issue
  template) — named in `architecture.md`'s CI/CD section, never created.
- Mockito self-attach / Netty macOS DNS resolver warnings — cosmetic,
  carried over since 2026-08-10, still not addressed.

Next:

- Fix the `MetersPage` "Installed" date-display-off-by-one-day bug found
  during validation above.
- Real 2-replica spike load-test validation once someone wants that closed
  out.
- Promote `frontend-test` to a required check once it's had a few more
  clean runs.
- GitHub Issues bug-tracking setup, then file the date bug as the first
  real issue through it.
