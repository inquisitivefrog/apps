# Patroni + PostgreSQL, for the HA investigation in docs/postgres-ha-scope.md. No official
# Docker Hub image bundles Patroni while preserving this project's pinned postgres:18.4 (community
# images like Zalando's Spilo pin their own Postgres version internally) -- built here explicitly
# to keep the exact version pin intact, per this project's declare-versions-explicitly convention.
FROM postgres:18.4

# Debian's postgres:18.4 base blocks system-wide `pip install` (PEP 668, "externally managed
# environment") -- a venv avoids needing --break-system-packages, matching this project's general
# avoidance of skipping safety guards to make a friction point go away.
RUN apt-get update && apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      python3-venv \
    && rm -rf /var/lib/apt/lists/* \
    && python3 -m venv /opt/patroni-venv \
    && /opt/patroni-venv/bin/pip install --no-cache-dir "patroni[consul]==4.1.5" "psycopg[binary]"

ENV PATH="/opt/patroni-venv/bin:${PATH}"

# Postgres refuses to run its own server process as root -- Patroni needs to run as the
# unprivileged `postgres` user (already created by the postgres:18.4 base image) from the start,
# since we bypass that image's own entrypoint.sh (which normally handles this) by overriding
# ENTRYPOINT below.
USER postgres

# Per-node config (name, connect addresses, credentials, Consul agent) is supplied via PATRONI_*
# environment variables in docker-compose.yml, which override values from the config file --
# matching this project's existing preference for env-var-driven config over mounted files where
# the tool supports it (Kafka's KAFKA_* vars, Redis's command-line flags). The `bootstrap` section
# specifically has no environment-variable equivalent (confirmed against Patroni's own
# ENVIRONMENT.rst) and is supplied by the mounted patroni.yml instead -- see docker-compose.yml.
ENTRYPOINT ["patroni"]
CMD ["/etc/patroni.yml"]
