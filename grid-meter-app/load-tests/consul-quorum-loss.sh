#!/usr/bin/env bash
# Postgres HA Stage 0 per docs/postgres-ha-scope.md: confirm Consul's own quorum behavior in
# isolation, before Postgres/Patroni ever touch it. Two sub-tests:
#   A) Kill the CURRENT LEADER (not just any follower -- the more rigorous test) while 2 of 3
#      remain. Confirm the remaining 2 elect a new leader and the cluster stays fully functional
#      (a real KV write/read succeeds).
#   B) With only 1 of 3 left, confirm the cluster correctly LOSES quorum and refuses to serve
#      writes requiring consensus, rather than silently continuing degraded. This is the
#      "known-good baseline" this doc's Stage 0 exists to establish before Patroni's own behavior
#      on top of Consul becomes a variable too.
#
# Every wait polls the actual condition (raft leader elected, quorum lost) rather than a fixed
# sleep, per docs/testing-strategy.md's "Test-infrastructure lesson" -- three prior HA passes hit
# this exact bug shape, no reason to reintroduce it here on day one of a fourth.
#
# This is a TRACKING/verification script -- always exits 0. A failure to lose quorum safely, or a
# failure to elect a new leader among 2 survivors, IS the reportable finding.
set -uo pipefail
cd "$(dirname "$0")/.."
source scripts/check-disk-headroom.sh || exit 1

RUN_TS="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="load-tests/vendor-bug-reports/postgres/runs/${RUN_TS}-stage0"
mkdir -p "$RUN_DIR"
OUTFILE="${RUN_DIR}/run-transcript.txt"
exec > >(tee "$OUTFILE") 2>&1
echo "Saving this run's output to $OUTFILE"

banner() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

CONSUL_SVCS="consul-1 consul-2 consul-3"

any_running_consul() {
  for svc in $CONSUL_SVCS; do
    if docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
      echo "$svc"
      return 0
    fi
  done
  return 1
}

current_leader_service() {
  local exec_svc; exec_svc=$(any_running_consul) || return 1
  local peers; peers=$(docker compose exec -T "$exec_svc" consul operator raft list-peers 2>/dev/null)
  local leader_addr; leader_addr=$(echo "$peers" | awk '$4=="leader" {print $3}' | cut -d: -f1)
  [ -z "$leader_addr" ] && return 1
  for svc in $CONSUL_SVCS; do
    local ip; ip=$(docker inspect "grid-meter-app-${svc}-1" --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)
    if [ "$ip" = "$leader_addr" ]; then
      echo "$svc"
      return 0
    fi
  done
  return 1
}

banner "Resetting to a clean 3-agent cluster"
docker compose up -d --force-recreate consul-1 consul-2 consul-3
echo "Waiting for all 3 to report alive, a leader elected, AND all 3 promoted to full voters --"
echo "confirmed empirically (2026-08-30) that 'alive + leader exists' alone is NOT sufficient:"
echo "Consul's autopilot has a stabilization delay before promoting a freshly-joined server to"
echo "full voting status, and a first run here caught exactly that window (2 nodes alive, but"
echo "only 1 was an actual raft voter), which shrank the effective quorum requirement and produced"
echo "a misleading result. Checking voter status directly instead of assuming a delay covers it."
READY=0
for i in $(seq 1 60); do
  # any_running_consul(), not hardcoded to consul-1 -- this loop runs right after
  # --force-recreate on all 3 agents, so any one of them could individually be the slowest to
  # come up; a fixed exec target risks reading 0/0 from a not-yet-up consul-1 even while
  # consul-2/consul-3 are both genuinely fine, the same "chaos script's own observation point
  # invalidated by unrelated state" shape docs/cross-project-lessons.md already names.
  POLL_SVC=$(any_running_consul 2>/dev/null || true)
  ALIVE=$([ -n "$POLL_SVC" ] && docker compose exec -T "$POLL_SVC" consul members 2>/dev/null | grep -c "alive" || echo 0)
  VOTERS=$([ -n "$POLL_SVC" ] && docker compose exec -T "$POLL_SVC" consul operator raft list-peers 2>/dev/null | grep -c "true" || echo 0)
  LEADER=$(current_leader_service 2>/dev/null || true)
  if [ "$ALIVE" -eq 3 ] && [ "$VOTERS" -eq 3 ] && [ -n "$LEADER" ]; then
    echo "3/3 alive, 3/3 voters, leader=$LEADER, at t+${i}s"
    READY=1
    break
  fi
  sleep 1
done
if [ "$READY" -eq 0 ]; then
  echo "Cluster never reached 3/3 alive + 3/3 voters + a leader within 60s -- aborting this run"
  echo "(a setup/join race, likely -retry-join's own backoff interval outracing this poll -- the"
  echo "same DNS/join-timing family of bug hit repeatedly this session with Kafka and Redis -- not"
  echo "a real Stage 0 finding about Consul's quorum behavior itself)."
  echo "--- diagnostic: raft peers at time of abort ---"
  docker compose exec -T "$(any_running_consul)" consul operator raft list-peers 2>&1
  exit 0
fi

EXEC_SVC=$(any_running_consul)
echo "--- baseline raft peers ---"
docker compose exec -T "$EXEC_SVC" consul operator raft list-peers

LEADER_SVC=$(current_leader_service)
echo "Current leader: $LEADER_SVC"
if [ -z "$LEADER_SVC" ]; then
  echo "Could not determine current leader -- aborting (setup problem, not a Stage 0 finding)."
  exit 0
fi

banner "SUB-TEST A: killing the current leader ($LEADER_SVC) -- 2 of 3 remain"
docker compose stop "$LEADER_SVC"

banner "Polling for the remaining 2 to elect a new leader"
NEW_LEADER_SVC=""
for i in $(seq 1 30); do
  NEW_LEADER_SVC=$(current_leader_service 2>/dev/null || true)
  if [ -n "$NEW_LEADER_SVC" ] && [ "$NEW_LEADER_SVC" != "$LEADER_SVC" ]; then
    echo "New leader elected: $NEW_LEADER_SVC at t+${i}s"
    break
  fi
  sleep 1
done
if [ -z "$NEW_LEADER_SVC" ]; then
  echo "No new leader elected within 30s -- real finding, not a script bug."
fi

banner "Confirming the 2-of-3 cluster is still fully functional (real KV write/read)"
MARKER="stage0-marker-$(date +%s)"
WRITE_RESULT=$(docker compose exec -T "$(any_running_consul)" consul kv put "$MARKER" "quorum-of-2-still-works" 2>&1)
echo "KV put result: $WRITE_RESULT"
READ_RESULT=$(docker compose exec -T "$(any_running_consul)" consul kv get "$MARKER" 2>&1)
echo "KV get result: $READ_RESULT"

banner "SUB-TEST B: killing a SECOND agent -- only 1 of 3 left, quorum should be LOST"
SECOND_KILL=""
for svc in $CONSUL_SVCS; do
  if [ "$svc" != "$LEADER_SVC" ] && docker compose ps --status running --format '{{.Service}}' | grep -qx "$svc"; then
    SECOND_KILL="$svc"
    break
  fi
done
echo "Stopping $SECOND_KILL (leaving only 1 of 3 alive)"
docker compose stop "$SECOND_KILL"

LAST_SVC=$(any_running_consul)
echo "Sole survivor: $LAST_SVC"

banner "Confirming quorum loss is detected (no leader) within 30s"
QUORUM_LOST="no"
for i in $(seq 1 30); do
  SOLE_LEADER=$(docker compose exec -T "$LAST_SVC" consul operator raft list-peers 2>/dev/null | awk '$4=="leader"')
  if [ -z "$SOLE_LEADER" ]; then
    QUORUM_LOST="yes"
    echo "No leader reported at t+${i}s -- quorum correctly lost"
    break
  fi
  sleep 1
done
echo "$LAST_SVC's own raft view:"
docker compose exec -T "$LAST_SVC" consul operator raft list-peers 2>&1

banner "Confirming writes requiring consensus are correctly REFUSED, not silently accepted"
MARKER_B="stage0b-marker-$(date +%s)"
# No `timeout` wrapper -- confirmed neither `timeout` nor `gtimeout` exists in this environment
# (a real gap caught on the first run: it silently failed with exit 127, which happened not to
# produce a false PASS only because a different check also failed that run). Not needed anyway --
# confirmed empirically that a quorum-less Consul agent fails fast with a 500 error, it doesn't
# hang, so `docker compose exec` returns promptly on its own.
WRITE_B=$(docker compose exec -T "$LAST_SVC" consul kv put "$MARKER_B" "should-not-succeed-without-quorum" 2>&1)
WRITE_B_EXIT=$?
echo "KV put attempt with no quorum: exit=$WRITE_B_EXIT, output: $WRITE_B"

banner "Restoring the full 3-agent cluster"
docker compose start "$LEADER_SVC" "$SECOND_KILL"
for i in $(seq 1 30); do
  # Same any_running_consul() fix as the setup loop above -- $LEADER_SVC/$SECOND_KILL are the two
  # nodes just restarted, so hardcoding to consul-1 specifically here would query one of them
  # while it's still settling, right when a fixed target is most likely to be the wrong one.
  POLL_SVC=$(any_running_consul 2>/dev/null || true)
  ALIVE=$([ -n "$POLL_SVC" ] && docker compose exec -T "$POLL_SVC" consul members 2>/dev/null | grep -c "alive" || echo 0)
  if [ "$ALIVE" -eq 3 ]; then
    echo "All 3 alive again at t+${i}s"
    break
  fi
  sleep 1
done
docker compose exec -T "$(any_running_consul)" consul operator raft list-peers 2>&1

banner "VERDICT SUMMARY"
echo "Sub-test A: killed leader ($LEADER_SVC), new leader elected among survivors: ${NEW_LEADER_SVC:-NONE}"
echo "  2-of-3 cluster functional (KV write/read): put=$WRITE_RESULT"
echo "Sub-test B: killed a second agent ($SECOND_KILL), quorum loss detected: $QUORUM_LOST"
echo "  Write attempted with no quorum: exit=$WRITE_B_EXIT (non-zero/timeout expected -- refused, not silently accepted)"
if [ -n "$NEW_LEADER_SVC" ] && [ "$WRITE_RESULT" = "Success! Data written to: $MARKER" ] && [ "$QUORUM_LOST" = "yes" ] && [ "$WRITE_B_EXIT" -ne 0 ]; then
  echo "PASS: 2-of-3 correctly elected a new leader and stayed functional; 1-of-3 correctly lost"
  echo "quorum and refused a write requiring consensus, rather than silently continuing degraded."
else
  echo "FAIL or UNEXPECTED -- review the transcript above; this is a real finding, not a script bug."
fi
