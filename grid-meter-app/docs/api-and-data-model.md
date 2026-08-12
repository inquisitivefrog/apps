# grid-meter-app — Data model & API

## Entities

### Meter

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `serialNumber` | string | Unique, indexed |
| `location` | string | Free-text for now (e.g. "123 Main St, Unit 4") — good enough for search/filter without needing a separate Location table |
| `status` | enum: `ACTIVE`, `INACTIVE`, `MAINTENANCE` | |
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
| `createdAt` | timestamp | |

**Design note:** readings are immutable events, not editable records — no
`PUT /readings/{id}`. If a bad reading needs correcting, the right move is a
new corrective reading, not mutating history. This is worth stating
explicitly in an interview; it's a real decision, not an omission.

### User

| Field | Type | Notes |
|---|---|---|
| `id` | UUID | Primary key |
| `username` | string | Unique, indexed |
| `passwordHash` | string | BCrypt, never returned in any response |
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
  dominant query shape, hit by both the API and Redis cache-miss fallback
- `meters`: unique index on `serial_number`
- `users`: unique index on `username`

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
via `/auth/login` when a token expires.

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
| `POST` | `/readings` | Ingest a reading | `201` | The endpoint JMeter hammers for load generation |
| `GET` | `/readings` | Search | `200` | Query: `meterId`, `from`, `to`, `minValue`, `maxValue`, `page`, `size` — all optional, but pagination is not: unbounded result sets are never allowed |
| `GET` | `/readings/{id}` | Read one | `200` / `404` | |
| `DELETE` | `/readings/{id}` | Delete | `204` / `404` | For test-data cleanup; not a normal operational path |

No `PUT /readings/{id}` — see immutability note above.

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
