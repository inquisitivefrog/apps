#!/usr/bin/env bash
# Deletes the kind cluster created by deploy.sh, and it alone (kind delete cluster only ever
# touches kind's own Docker containers, never the docker-compose.yml stack — the two deployment
# models are fully independent).
set -euo pipefail
kind delete cluster --name grid-meter
