-- Stage A of docs/resilience-scope.md's outbox pattern: write path only, no reconciler yet.
-- Holds readings whose Kafka publish failed after client-side retries were exhausted (see
-- ReadingService.ingest()'s whenComplete callback) -- previously these were only logged/counted
-- and the reading itself was gone forever. Deliberately minimal for this stage: no status/claim
-- columns for a reconciler yet (Stage D), no index beyond the primary key -- nothing queries this
-- table yet besides the insert. Reconciler-support columns land in a later migration when Stage D
-- is actually built, not now, matching this project's incremental-scope convention elsewhere.
CREATE TABLE reading_outbox (
    id                UUID PRIMARY KEY,
    meter_id          UUID         NOT NULL,
    reading_timestamp TIMESTAMPTZ  NOT NULL,
    received_at       TIMESTAMPTZ  NOT NULL,
    value             NUMERIC(12,3) NOT NULL,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT now()
);
