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

**Indexes:**
- `readings`: composite index on `(meter_id, reading_timestamp)` — the
  dominant query shape, hit by both the API and Redis cache-miss fallback
- `meters`: unique index on `serial_number`

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
not part of the versioned application contract.
