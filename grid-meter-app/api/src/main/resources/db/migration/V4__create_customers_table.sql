CREATE TABLE customers (
    id         UUID PRIMARY KEY,
    name       VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Observability-only tenancy (docs/multi-tenancy-scope.md, confirmed 2026-08-27): every existing
-- user and meter is assigned to this one default customer so the NOT NULL FK columns below can be
-- backfilled before being enforced. No API access-control change — every authenticated user still
-- sees every customer's data; customerId exists to be propagated through logs/traces for reporting.
INSERT INTO customers (id, name, created_at, updated_at) VALUES (
    '11111111-1111-1111-1111-111111111111',
    'Default Customer',
    now(),
    now()
);

ALTER TABLE users ADD COLUMN customer_id UUID;
UPDATE users SET customer_id = '11111111-1111-1111-1111-111111111111';
ALTER TABLE users ALTER COLUMN customer_id SET NOT NULL;
ALTER TABLE users ADD CONSTRAINT fk_users_customer FOREIGN KEY (customer_id) REFERENCES customers (id);

ALTER TABLE meters ADD COLUMN customer_id UUID;
UPDATE meters SET customer_id = '11111111-1111-1111-1111-111111111111';
ALTER TABLE meters ALTER COLUMN customer_id SET NOT NULL;
ALTER TABLE meters ADD CONSTRAINT fk_meters_customer FOREIGN KEY (customer_id) REFERENCES customers (id);
