#!/usr/bin/env python3
"""Controlled retest of the Postgres HA "paired-agent" self-demotion hypothesis
(docs/postgres-ha-scope.md, Stage 6 self-demotion timing section).

The original Stage 6 pass claimed self-demotion is fast (~3s) when the leader's own
paired Consul agent (patroni-N <-> consul-N, same number, see docker-compose.yml) is
among the two killed, and slow (~10-15s) when it survives but the cluster still loses
quorum. Re-deriving the original 3 runs directly from their own raw evidence
(vendor-bug-reports/postgres/runs/20260901-stage6-run*.txt) showed the doc's summary
table didn't match that evidence, and the corrected numbers don't cleanly support the
theory either -- two runs of the SAME condition (own agent killed) produced 3000ms and
10000ms, a 3x spread as large as the gap between the two hypothesized conditions.

This script tests it properly: N repeats of each condition (default 3), with two fixes
the original test lacked:
  1. Fine-grained polling (real python time.time(), ~100ms resolution, not bash's
     whole-second SECONDS builtin the original script used -- which quantized every
     result to a 1-second boundary and could fully explain the original "10000ms"
     coincidences on its own, independent of any real mechanism).
  2. Mechanism-level instrumentation: captures the leader's own DEBUG-level Patroni
     logs (docs/postgres-ha-scope.md's Stage 2 already proved this logging works) for
     the actual Consul-client failure signature, not just the outcome-level
     self-demotion timestamp -- directly testing "connection refused" (own agent dead)
     vs "accepted then failed at the raft layer" (own agent alive, no quorum) rather
     than inferring it from total elapsed time alone.

Also reports whether observed self-demotion times cluster near multiples of the live
loop_wait value (confirmed via `patronictl show-config`, not assumed) -- ruling out
Patroni's own discrete polling cycle as a confound before crediting any paired-agent
explanation.

Usage: ./postgres-consul-self-demotion-timing-test.py [--repeats N]
Requires the full stack up (docker compose up -d), matching every other script in this
directory. Restores all Consul agents before exiting, including on error/interrupt.
"""
import argparse
import json
import re
import subprocess
import sys
import time
from datetime import datetime, timezone

COMPOSE = ["docker", "compose"]
ALL_CONSUL = ["consul-1", "consul-2", "consul-3"]
POLL_TIMEOUT_S = 25
POLL_INTERVAL_S = 0.0  # no artificial sleep -- docker exec's own ~90ms round-trip is the limiter


def run(args, check=True, capture=True):
    return subprocess.run(args, capture_output=capture, text=True, check=check)


def compose_exec(service, *cmd):
    return run(COMPOSE + ["exec", "-T", service] + list(cmd), check=False)


def patronictl_exec(*cmd):
    """Runs a patronictl command via whichever Patroni node is actually running, not a hardcoded
    one. This script only ever kills Consul agents (never Patroni containers directly), so the
    real risk isn't this script's own action -- it's the same residual-state pattern found
    repeatedly elsewhere in this project today (a prior, unrelated test run leaving patroni-1
    specifically down). Checks container status via `docker compose ps` first, matching the
    proven bash pattern used throughout this pass, rather than string-matching error output
    (fragile -- a stopped container's exec failure and a real patronictl-level error look
    different and shouldn't be conflated)."""
    running = run(COMPOSE + ["ps", "--status", "running", "--format", "{{.Service}}"]).stdout
    for svc in ("patroni-1", "patroni-2", "patroni-3"):
        if svc in running.splitlines():
            return compose_exec(svc, "patronictl", "-c", "/etc/patroni.yml", *cmd)
    raise RuntimeError("No running Patroni node found to exec through.")


def get_leader(retries=5, delay=2.0):
    """Returns (leader_service, leader_number) e.g. ('patroni-2', '2'). Confirmed live,
    not assumed, since a prior trial's restore could in principle leave a different node
    as leader (self-demotion during quorum loss never elects a replacement, but this is
    checked fresh every trial regardless, per this project's own standing discipline).

    Retries a few times rather than failing on the first miss: found live (2026-09-02,
    at a reduced retry_timeout=3s) that `patronictl list` itself can transiently fail
    with "Consul is not responding properly" for several seconds right after a prior
    trial's restore, even with no agents currently down -- a tight retry_timeout makes
    Consul's own normal consistent-read round-trip marginal immediately post-disruption,
    which is itself a real finding (see docs/postgres-ha-scope.md's scaling-experiment
    section), not just a script robustness gap to paper over silently."""
    last_out = ""
    for attempt in range(retries):
        r = patronictl_exec("list")
        out = r.stdout
        last_out = out
        for line in out.splitlines():
            if "Leader" in line:
                parts = [p.strip() for p in line.split("|")]
                member = parts[1] if len(parts) > 1 else ""
                m = re.search(r"patroni-(\d)", member)
                if m:
                    return f"patroni-{m.group(1)}", m.group(1)
        time.sleep(delay)
    raise RuntimeError(f"Could not identify leader from patronictl output after "
                        f"{retries} attempts:\n{last_out}")


def pg_is_in_recovery(service):
    r = compose_exec(service, "psql", "-U", "postgres", "-Atc", "SELECT pg_is_in_recovery();")
    if r.returncode != 0:
        return None  # unreachable, not the same as "false"
    return r.stdout.strip()


def wait_for_quorum(timeout_s=40):
    """Confirms quorum is back AND that whichever node patronictl now reports as leader
    has actually finished its own recovery transition (pg_is_in_recovery() == 'f'), not
    just that `patronictl list` succeeds and the word "Leader" appears somewhere in its
    output. Found the hard way: without the second check, the very next trial's
    get_leader() could pick up a node patronictl still labeled "Leader" from a stale
    cached view while its Postgres instance was still mid-recovery from the previous
    trial's self-demotion -- producing a spurious near-zero "demotion" on the next
    trial's very first poll instead of a real measurement. Confirmed happening live
    (2026-09-02): 2 of 3 "different"-condition trials in the first full run showed
    demoted_at ~0.24s with no prior "f" sample at all, exactly this failure shape."""
    start = time.time()
    while time.time() - start < timeout_s:
        r = patronictl_exec("list")
        if r.returncode == 0 and "Leader" in r.stdout:
            try:
                leader_service, _ = get_leader()
            except RuntimeError:
                time.sleep(1)
                continue
            if pg_is_in_recovery(leader_service) == "f":
                return True
        time.sleep(1)
    return False


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def run_trial(condition, leader_service, leader_num, other_to_kill, log_path):
    """condition: 'own' (leader's own paired agent is among the 2 killed) or
    'different' (leader's own agent survives, the other 2 are killed).
    other_to_kill: for condition 'own', which of the two non-own agents to also kill
    (the third, non-killed one becomes the survivor). Ignored for 'different'."""
    own_agent = f"consul-{leader_num}"
    non_own = [a for a in ALL_CONSUL if a != own_agent]

    if condition == "own":
        kill = [own_agent, other_to_kill]
    elif condition == "different":
        kill = list(non_own)
    else:
        raise ValueError(condition)
    survivor = [a for a in ALL_CONSUL if a not in kill][0]

    print(f"  Leader: {leader_service} (own agent {own_agent}) | condition={condition} | "
          f"killing {kill} | surviving {survivor}")

    # Start tailing the leader's own Patroni DEBUG logs *before* the kill, so the
    # capture window cleanly brackets the failure -- avoids racing docker's own log
    # buffering the way this project's earlier "docker logs buffering race" lesson
    # warned about (see docs/testing-strategy.md); we read the file back afterward,
    # not mid-stream, so any buffering delay resolves before we ever parse it.
    # --since is required, not cosmetic: without it, `docker compose logs -f` dumps the
    # entire historical backlog before following live (confirmed live -- 24k+ lines from
    # 2 seconds of "follow" time in a pilot check) which would let an old, unrelated
    # Consul-failure log line from an earlier test in this session falsely match as
    # "this trial's" mechanism line.
    log_since = now_iso()
    log_file = open(log_path, "w")
    log_proc = subprocess.Popen(
        COMPOSE + ["logs", "-f", "--no-log-prefix", "--since", log_since, leader_service],
        stdout=log_file, stderr=subprocess.STDOUT,
    )
    time.sleep(0.3)  # let the log-follow process actually attach before the kill

    kill_wall_time = time.time()
    kill_iso = now_iso()
    run(COMPOSE + ["stop"] + kill, check=True)

    samples = []
    demoted_at = None
    start = time.time()
    last_state = None
    while time.time() - start < POLL_TIMEOUT_S:
        t = time.time()
        state = pg_is_in_recovery(leader_service)
        samples.append((t - kill_wall_time, state))
        if state == "t" and last_state != "t":
            demoted_at = t - kill_wall_time
            break
        last_state = state
        if POLL_INTERVAL_S:
            time.sleep(POLL_INTERVAL_S)

    demote_wall_time = time.time()
    time.sleep(1.5)  # let a bit more log activity land before stopping the tail
    log_proc.terminate()
    log_proc.wait(timeout=5)
    log_file.close()

    # Restore both killed agents, wait for real quorum before the next trial -- never
    # assume "docker compose start" returning means Consul itself has actually
    # re-formed quorum, per this project's standing "confirm live, don't assume"
    # discipline (same shape as the volume/bootstrap lessons from the idempotency work).
    run(COMPOSE + ["start"] + kill, check=True)
    quorum_back = wait_for_quorum()

    with open(log_path) as f:
        log_lines = f.readlines()

    mechanism_line, mechanism_offset_s = find_mechanism_line(log_lines, kill_iso)

    return {
        "condition": condition,
        "leader": leader_service,
        "own_agent": own_agent,
        "killed": kill,
        "survivor": survivor,
        "demoted_at_s": round(demoted_at, 3) if demoted_at is not None else None,
        "last_false_before_s": round(
            [s[0] for s in samples if s[1] == "f"][-1], 3
        ) if any(s[1] == "f" for s in samples) else None,
        "quorum_restored": quorum_back,
        "mechanism_log_line": mechanism_line,
        "mechanism_detected_at_s": mechanism_offset_s,
        "sample_count": len(samples),
    }


CONSUL_FAILURE_PATTERNS = re.compile(
    r"(ConnectionError|Max retries exceeded|Failed to establish|ConnectTimeout|"
    r"ReadTimeout|Connection refused|Consul is not accessible|CriticalHealthCheck|"
    r"raft|leadership lost|no leader)",
    re.IGNORECASE,
)


PATRONI_TS_RE = re.compile(r"^(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})")


def find_mechanism_line(log_lines, kill_iso):
    """Scans captured DEBUG log lines for the first Consul-client failure signature and
    returns (line_text, offset_seconds_from_kill). Patroni's container clock was
    confirmed live (`date -u` == `date`) to run in UTC, matching this script's own
    kill_iso timestamp, so the two are directly comparable -- not assumed, checked once
    live before trusting it for every trial."""
    kill_dt = datetime.fromisoformat(kill_iso)
    for line in log_lines:
        if CONSUL_FAILURE_PATTERNS.search(line):
            m = PATRONI_TS_RE.match(line)
            offset = None
            if m:
                line_dt = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S,%f").replace(
                    tzinfo=timezone.utc
                )
                offset = round((line_dt - kill_dt).total_seconds(), 3)
            return line.strip(), offset
    return None, None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repeats", type=int, default=3)
    parser.add_argument("--conditions", default="own,different",
                         help="comma-separated subset of conditions to run, e.g. 'different' "
                              "to re-run just one condition without redoing a clean one")
    args = parser.parse_args()

    print("=== Confirming live loop_wait/ttl/retry_timeout (not assumed) ===")
    cfg = patronictl_exec("show-config").stdout
    print(cfg)
    loop_wait = None
    for line in cfg.splitlines():
        if line.startswith("loop_wait:"):
            loop_wait = int(line.split(":")[1].strip())
    if loop_wait is None:
        print("Could not parse loop_wait, aborting", file=sys.stderr)
        sys.exit(1)

    results = []
    other_agents_cycle = None

    try:
        for condition in args.conditions.split(","):
            for i in range(args.repeats):
                leader_service, leader_num = get_leader()
                own_agent = f"consul-{leader_num}"
                non_own = [a for a in ALL_CONSUL if a != own_agent]
                other_to_kill = non_own[i % len(non_own)]  # alternate across repeats

                print(f"\n=== Trial: condition={condition} run={i+1}/{args.repeats} ===")
                log_path = f"results/self-demotion-{condition}-run{i+1}-{leader_service}.log"
                result = run_trial(condition, leader_service, leader_num, other_to_kill, log_path)
                result["run"] = i + 1
                results.append(result)
                print(f"  -> demoted_at={result['demoted_at_s']}s "
                      f"last_false_before={result['last_false_before_s']}s "
                      f"quorum_restored={result['quorum_restored']}")
                if result["mechanism_log_line"]:
                    print(f"  -> mechanism line at {result['mechanism_detected_at_s']}s: "
                          f"{result['mechanism_log_line'][:160]}")
                else:
                    print("  -> no Consul-failure-pattern DEBUG line found in capture window")

                if not result["quorum_restored"]:
                    print("WARNING: quorum did not visibly restore before timeout -- "
                          "pausing before next trial", file=sys.stderr)
                    time.sleep(10)
                else:
                    time.sleep(3)  # brief settle before the next trial's kill

    finally:
        # Safety net: never leave agents stopped if something above raised.
        run(COMPOSE + ["start"] + ALL_CONSUL, check=False)

    print("\n=== Summary ===")
    print(f"loop_wait = {loop_wait}s (multiples: {loop_wait}s, {2*loop_wait}s, {3*loop_wait}s)")
    for r in results:
        near_multiple = ""
        if r["demoted_at_s"] is not None:
            remainder = r["demoted_at_s"] % loop_wait
            if remainder < 1.0 or remainder > loop_wait - 1.0:
                near_multiple = f"  <-- within 1s of a loop_wait ({loop_wait}s) multiple"
        print(f"  [{r['condition']:>9}] run {r['run']}: leader={r['leader']} "
              f"own_agent_killed={r['own_agent'] in r['killed']} "
              f"demoted_at={r['demoted_at_s']}s{near_multiple}")

    with open("results/self-demotion-timing-results.json", "w") as f:
        json.dump({"loop_wait": loop_wait, "results": results}, f, indent=2)
    print("\nFull results written to results/self-demotion-timing-results.json")


if __name__ == "__main__":
    main()
