-- docs/idempotency-scope.md: POST /readings requires an Idempotency-Key header, and the real
-- guarantee ("no second row") is enforced here, not by the Redis fast-path alone.
--
-- Added in three steps rather than a single NOT NULL column, since this table can already hold
-- rows from before this feature existed: a bare `ADD COLUMN ... NOT NULL` fails outright against
-- any non-empty table with no default. Backfilled with each row's own already-unique `id` cast to
-- text -- a synthetic value, not a real client-supplied key, but sufficient to satisfy the new
-- NOT NULL/UNIQUE constraints for rows that predate this feature without inventing a fake
-- collision risk between them.
ALTER TABLE readings ADD COLUMN idempotency_key VARCHAR(255);

UPDATE readings SET idempotency_key = id::text WHERE idempotency_key IS NULL;

ALTER TABLE readings ALTER COLUMN idempotency_key SET NOT NULL;

CREATE UNIQUE INDEX ux_readings_idempotency_key ON readings (idempotency_key);
