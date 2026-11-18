#!/usr/bin/env bash
# Seeds load-test users loadtest-001 .. loadtest-<count> (default 100) so each JMeter thread can log
# in as its own user, rather than every thread sharing the demo user's one token -- see
# common/user-login.jmx. Without this, the Service Health dashboard's "Active users" reads 1 no
# matter how many threads run.
#
# Inserted straight into Postgres, NOT via a Flyway migration: migrations run in every
# environment, including the cloud deployments, and throwaway load-test accounts don't belong
# there. Idempotent (ON CONFLICT DO NOTHING) -- run.sh calls it before every run.
#
# Targets the kind cluster if its postgres Deployment is reachable, otherwise the local Compose
# stack (through Traefik's :55432 route to the current Patroni primary, the same path the api uses).
#
# Every user shares one password: LoadTest!2026 (override the JMeter side with
# -JloadTestPassword=...). The hash below is bcrypt cost 10, the same format as the demo user's
# hash in V3__create_users_table.sql, generated with:
#   htpasswd -bnBC 10 "" 'LoadTest!2026' | tr -d ':\n'
#
# Usage: ./seed-users.sh [count]
set -euo pipefail

COUNT="${1:-100}"
if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ] || [ "$COUNT" -gt 999 ]; then
  echo "count must be 1-999 (usernames are zero-padded to 3 digits), got: $COUNT" >&2
  exit 1
fi

SQL=$(cat <<EOF
INSERT INTO users (id, username, password_hash, customer_id)
SELECT gen_random_uuid(),
       format('loadtest-%s', lpad(n::text, 3, '0')),
       '\$2y\$10\$ZQY/KW./jmmQ9PnnbP3T5OZQ6bI4n8jAKzQS24p84PebEghFi2wpm',
       '11111111-1111-1111-1111-111111111111'
FROM generate_series(1, ${COUNT}) AS n
ON CONFLICT (username) DO NOTHING;
SELECT count(*) FROM users WHERE username LIKE 'loadtest-%';
EOF
)

if kubectl --context kind-grid-meter get deployment postgres >/dev/null 2>&1; then
  TARGET="kind (deployment/postgres)"
  run_psql() { kubectl --context kind-grid-meter exec -i deployment/postgres -- psql -U gridmeter -d gridmeter -v ON_ERROR_STOP=1 -qAt; }
else
  TARGET="Compose (traefik:55432 -> Patroni primary)"
  run_psql() { docker compose exec -T -e PGPASSWORD=gridmeter patroni-1 psql -h traefik -p 55432 -U gridmeter -d gridmeter -v ON_ERROR_STOP=1 -qAt; }
fi

TOTAL=$(printf '%s\n' "$SQL" | run_psql | tail -1)
echo "Seeded load-test users on $TARGET: loadtest-001..loadtest-$(printf '%03d' "$COUNT") requested, $TOTAL present."
