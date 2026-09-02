# grid-meter-app — Data model & API

## Entities

### Meter

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `serialNumber` | string | Unique, indexed |
| `location` | string | Free-text for now (e.g. "123 Main St, Unit 4") — good enough for search/filter without needing a separate Location table |
| `status` | enum: `ACTIVE`, `INACTIVE`, `MAINTENANCE` | |
| `customerId` | UUID | Foreign key → Customer. Every meter belongs to exactly one customer — see "Multi-tenancy" below |
| `installedAt` | timestamp | |
| `createdAt` / `updatedAt` | timestamp | Standard audit fields |

### Reading

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `meterId` | UUID | Foreign key → Meter |
| `readingTimestamp` | timestamp | When the reading was taken at the meter |
| `receivedAt` | timestamp | When the server ingested it — the gap between this and `readingTimestamp` is a useful latency metric for the observability story |
| `value` | decimal | kWh |
| `idempotencyKey` | string | Unique, indexed. Client-supplied via the `Idempotency-Key` header — see "Idempotency" below |
| `createdAt` | timestamp | |

**Design note:** readings are immutable events, not editable records — no
`PUT /readings/{id}`. If a bad reading needs correcting, the right move is a
new corrective reading, not mutating history. This is worth stating
explicitly in an interview; it's a real decision, not an omission.

### Customer

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `name` | string | |
| `createdAt` / `updatedAt` | timestamp | Standard audit fields |

Deliberately minimal — no billing fields, no plan/tier field. Added for
**observability-only tenancy**: `customerId` propagates through
logs/traces for reporting (blast-radius/customer-impact queries), but
does **not** change API access control. Every authenticated user still
sees every customer's data, exactly as before this entity existed — see
`docs/multi-tenancy-scope.md` for the full reasoning, including why
full tenant isolation was deliberately *not* built in this pass, and why
`customerId` is a Loki/Tempo field, never a raw Prometheus label
(cardinality). Component tests explicitly assert this non-isolation is
intentional and current (`search_returns...AcrossAllCustomers_documentingCurrentNonIsolation`),
not an untested assumption.

A single **"Default Customer"** row (`id`
`11111111-1111-1111-1111-111111111111`) is Flyway-seeded — the same
migration assigns the existing seed `demo` user and any pre-existing
seed/test meters to it, the same way `V3` seeds the `demo` user itself.
Confirmed live against the running database, not assumed from the
migration's intent.

### User

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `username` | string | Unique, indexed |
| `passwordHash` | string | BCrypt, never returned in any response |
| `customerId` | UUID | Foreign key → Customer. One customer per user for this pass — a many-to-many User↔Customer model is a documented future enhancement, not built |
| `createdAt` / `updatedAt` | timestamp | Standard audit fields |

No `role` column — deliberate, not an oversight. Nothing in this app today
gates behavior by role (no admin-vs-viewer split, no differentiated UI), so
adding one now would be speculative structure against this project's own
minimal-scope ethos. Every authenticated request carries a single implicit
`ROLE_USER` authority granted at the Spring Security layer, not persisted.
There is no self-registration endpoint — the one seed user (`demo`) is
created by a Flyway migration, the same way `gridmeter`/`gridmeter` is a
hardcoded dev-only DB credential in `docker-compose.yml`.

**Indexes:**
- `readings`: composite index on `(meter_id, reading_timestamp)` — the
  dominant query shape, hit by both the API and Redis cache-miss fallback;
  also a unique index on `idempotency_key`
- `meters`: unique index on `serial_number`
- `users`: unique index on `username`

## Multi-tenancy

`Meter.customerId` and `User.customerId` exist for **reporting purposes
only** — see the `Customer` entity above and
`docs/multi-tenancy-scope.md` for the full decision. The JWT issued at
`/auth/login` carries a `customerId` claim (mirroring the existing
single `ROLE_USER`-authority-at-the-Security-layer pattern, avoiding a
per-request DB lookup), but **no endpoint currently scopes its results
by it** — `GET /meters` and `GET /readings` return data across all
customers today, and that non-isolation is deliberately tested, not
merely untested. Full per-customer API isolation is explicitly deferred
as its own future decision, not assumed to follow automatically from
this entity's existence.

## Auth

Every `/api/v1/**` route requires a valid JWT — including `POST
/readings`, the endpoint JMeter hammers for load generation. This was a
deliberate choice over leaving ingestion open as a separate
machine-to-machine path: it's a more realistic security posture for an SRE
demo, at the cost of a future JMeter test plan needing a login step (HTTP
Header Manager + a correlation extractor) before its load-generating thread
group. See `architecture.md`'s "Authentication" section for the reasoning
behind JWT-over-sessions and the no-refresh-token tradeoff.

### `POST /api/v1/auth/login`

The only unauthenticated `/api/v1` route.

Request:
```json
{ "username": "demo", "password": "GridMeter!Demo2026" }
```

Success (`200`):
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "expiresInSeconds": 3600
}
```

Failure (`401`, identical for unknown username and wrong password —
deliberately avoids leaking which one was wrong):
```json
{
  "timestamp": "2026-08-11T...",
  "status": 401,
  "error": "Unauthorized",
  "message": "Invalid username or password",
  "details": []
}
```

### Using the token

Every other `/api/v1/**` request needs:
```
Authorization: Bearer <accessToken>
```

A missing, invalid, or expired token gets the same `401` `ApiError` shape
as above, with `message: "A valid Bearer token is required"`. Tokens expire
60 minutes after issuance — there is no refresh endpoint; re-authenticate
via `/auth/login` when a token expires. The token's claims include
`customerId` — see "Multi-tenancy" below for what that is and, just as
importantly, what it does not currently do.

## API — `/api/v1`

### Meters

| Method | Path | Purpose | Success | Notes |
|---|---|---|---|---|
| `POST` | `/meters` | Create | `201` | Body: serialNumber, location, status, installedAt |
| `GET` | `/meters` | Search / list | `200` | Query: `location`, `status`, `page`, `size` |
| `GET` | `/meters/{id}` | Read one | `200` / `404` | |
| `PUT` | `/meters/{id}` | Update | `200` / `404` | Full replace |
| `DELETE` | `/meters/{id}` | Delete | `204` / `404` | |

### Readings

| Method | Path | Purpose | Success | Notes |
|---|---|---|---|---|
| `POST` | `/readings` | Ingest a reading | `201` | The endpoint JMeter hammers for load generation. Requires an `Idempotency-Key` header — see "Idempotency" below |
| `GET` | `/readings` | Search | `200` | Query: `meterId`, `from`, `to`, `minValue`, `maxValue`, `page`, `size` — all optional, but pagination is not: unbounded result sets are never allowed |
| `GET` | `/readings/{id}` | Read one | `200` / `404` | |
| `DELETE` | `/readings/{id}` | Delete | `204` / `404` | For test-data cleanup; not a normal operational path |

No `PUT /readings/{id}` — see immutability note above.

### Idempotency

`POST /readings` requires an `Idempotency-Key` header (client-generated,
a UUID is recommended but not enforced beyond non-empty). A request
missing this header is rejected with `400` before any other processing.

Resubmitting the same key returns the original `201` response without
creating a second reading — safe to retry on any ambiguous failure
(timeout, connection reset, 5xx) using the same key. A different key
is always treated as a new, distinct reading, even if the body is
identical to a prior request.

See `docs/idempotency-scope.md` for the full design (the two-layer
Redis-fast-path + unique-DB-constraint guarantee) and the real failure
mode that motivated it (Postgres Stage 7's re-execution surfaced a
client-observed failure whose write had actually already landed).

### Pagination

All list/search endpoints return:

```json
{
  "content": [ ... ],
  "page": 0,
  "size": 20,
  "totalElements": 143,
  "totalPages": 8
}
```

Default `size=20`, max `size=100` — enforced server-side, not just
documented, so a misbehaving client (or JMeter script) can't request an
unbounded page.

### Ops endpoints (via Spring Boot Actuator, not versioned)

| Path | Purpose |
|---|---|
| `/actuator/health` | Liveness/readiness |
| `/actuator/prometheus` | Metrics scrape target |

These sit outside `/api/v1` deliberately — they're infrastructure concerns,
not part of the versioned application contract. They're also the sole
exception to "every route requires a JWT" — both are `permitAll()`'d in
`SecurityConfig`, since a liveness probe or a Prometheus scrape can't carry
a bearer token.
