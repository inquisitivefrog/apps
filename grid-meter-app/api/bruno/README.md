# grid-meter-api — Bruno collection

Manual/exploratory API testing, per `docs/testing-strategy.md`'s "API
tooling" section. Chosen over Postman because it needs no cloud account and
nothing leaves the machine — collections are plain text (`.bru` files),
versioned in git, reviewable in a PR like any other change.

This complements, not duplicates, the automated REST Assured suite
(`api/src/test/java/.../*ApiComponentTest.java` and `*ApiIT.java`) — Bruno
is for a human poking at the API by hand; REST Assured is what actually
gates CI.

## Setup

1. Open Bruno, "Open Collection", point it at this `bruno/` directory.
2. Select the **local** environment (top-right environment picker) — it
   points `baseUrl` at `http://localhost/api/v1` and `rootUrl` at
   `http://localhost`, matching `docker compose up`'s Traefik routing.
3. Bring the stack up: `docker compose up traefik api postgres kafka redis`
   (minimum needed for these requests) from the repo root.

## Running requests

Run `auth/Login` first — its post-response script stores the JWT in a
collection variable (`accessToken`) that every other request inherits via
the collection-level bearer auth in `collection.bru`. Tokens expire 60
minutes after issuance (see `docs/architecture.md`'s "Authentication"
section); re-run Login if later requests start failing with 401.

Folders are numbered by `seq` in each `folder.bru`, and a full run (Bruno
GUI's "Run" on the collection root, or `bru run --env local` from this
directory) executes folders in that order, so it doubles as a working
end-to-end smoke sequence, not just a suggested reading order:

1. **auth/** — login, invalid-credentials (401, anti-enumeration), and an
   explicit unauthenticated-request check (401, proving every `/api/v1/**`
   route is gated).
2. **meters/** — create → search → get → update. Create sets the `meterId`
   variable that readings/ and cleanup/ reuse.
3. **readings/** — ingest → search → get → **reject-put (405)**. The 405
   check exists because readings are immutable events — see
   `docs/api-and-data-model.md`'s design note — and
   `docs/testing-strategy.md` calls out asserting the rejection explicitly,
   not just noting the endpoint's absence.
4. **ops/** — `/actuator/health` and `/actuator/prometheus`, the two routes
   outside `/api/v1` and the only ones that don't require a token.
5. **cleanup/** — delete reading, then delete meter. Deliberately its own
   folder that runs *last*, not nested inside meters/ or readings/: Bruno
   runs folders as whole units in `seq` order, so a `Delete Meter` request
   living inside meters/ would run before readings/ ever fires, deleting
   the meter the `meterId` variable points at and breaking every request
   downstream (found by actually running `bru run --env local` headlessly
   — see `scripts/verify-bruno-collection.sh` for the curl-based
   equivalent check). Reading is deleted before its meter here for the
   same reason the old same-folder ordering mattered: a meter with
   readings still pointing at it hits the FK constraint if deleted first.
