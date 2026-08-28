#!/usr/bin/env bash
# Polls a single Grafana alert rule's actual state at a fixed interval and prints a timestamped
# transcript -- built to directly witness a Normal -> Pending -> Firing transition rather than
# check once and infer from timing math. Originally written as a one-off to confirm the "Reading
# delivery failures" rule (observability/alerting/rules.yml) actually reaches firing, not just
# pending, during the sustained Kafka quorum-loss scenario in kafka-ha-demo.sh -- generalized here
# since watching any rule's real state through a transition is broadly useful, not specific to that
# one investigation. Deliberately does NOT trigger any fault itself -- pair it with whatever outage
# script (kafka-ha-demo.sh, chaos-demo.sh, misconfigured-spike-demo.sh) or manual action you're
# using to make the condition true, then run this alongside/after to watch the rule react.
#
# Usage: load-tests/watch-alert-rule.sh <rule-name-substring> [poll-interval-seconds] [poll-count] [prometheus-metric-name]
#   rule-name-substring: case-insensitive match against the rule's title, e.g. "delivery",
#     "tomcat", "traefik edge". Matches Grafana's /api/prometheus/grafana/api/v1/rules "name" field.
#   poll-interval-seconds: default 15.
#   poll-count: default 16 (i.e. 240s total at the default interval).
#   prometheus-metric-name: optional -- if given, also prints this metric's current value from
#     /actuator/prometheus alongside the rule state each poll (e.g. reading_delivery_failures_total).
#
# Example: load-tests/watch-alert-rule.sh delivery 15 16 reading_delivery_failures_total
set -uo pipefail

RULE_MATCH="${1:?Usage: $0 <rule-name-substring> [poll-interval-seconds] [poll-count] [prometheus-metric-name]}"
POLL_INTERVAL="${2:-15}"
POLL_COUNT="${3:-16}"
METRIC_NAME="${4:-}"

GRAFANA_HOST="http://localhost:3001"

check_state() {
  curl -s -u admin:admin "${GRAFANA_HOST}/api/prometheus/grafana/api/v1/rules" | python3 -c "
import sys, json
match = '$RULE_MATCH'.lower()
d = json.load(sys.stdin)
found = False
for g in d['data']['groups']:
    for r in g.get('rules', []):
        if match in r.get('name','').lower():
            print(r.get('state'))
            found = True
if not found:
    print('NO_MATCHING_RULE')
"
}

check_metric() {
  [ -z "$METRIC_NAME" ] && return
  curl -s http://localhost/actuator/prometheus | grep "^${METRIC_NAME} " | awk '{print $2}'
}

initial_state=$(check_state)
if [ "$initial_state" = "NO_MATCHING_RULE" ]; then
  echo "No rule found matching '$RULE_MATCH' -- check the exact title in observability/alerting/rules.yml" >&2
  exit 1
fi
echo "$(date +%H:%M:%S) [+0s] state=$initial_state $( [ -n "$METRIC_NAME" ] && echo "$METRIC_NAME=$(check_metric)")"

last_state="$initial_state"
for i in $(seq 1 "$POLL_COUNT"); do
  sleep "$POLL_INTERVAL"
  state=$(check_state)
  elapsed=$((i * POLL_INTERVAL))
  changed=""
  [ "$state" != "$last_state" ] && changed=" <-- CHANGED from $last_state"
  metric_str=""
  [ -n "$METRIC_NAME" ] && metric_str=" $METRIC_NAME=$(check_metric)"
  echo "$(date +%H:%M:%S) [+${elapsed}s] state=${state}${metric_str}${changed}"
  last_state="$state"
done
