CREATE TABLE users (
    id            UUID PRIMARY KEY,
    username      VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX ux_users_username ON users (username);

-- Demo/dev seed user — mirrors the hardcoded gridmeter/gridmeter DB credential already
-- in docker-compose.yml. Username: demo / password: GridMeter!Demo2026.
-- Flyway migrations run outside the Service layer, so a literal UUID and a precomputed
-- bcrypt hash belong here rather than a UUID.randomUUID()/BCryptPasswordEncoder call —
-- this is the one deliberate exception to "the app generates ids/hashes at runtime".
INSERT INTO users (id, username, password_hash, created_at, updated_at) VALUES (
    'a3f1e4b2-3d9a-4c7e-8b6a-1f2e3d4c5b6a',
    'demo',
    '$2y$10$BKZDig38Hd/b5KpIUOr5cuBAHiqi4LUapU5pr5lsEOLdA5nE9I64K',
    now(),
    now()
);
