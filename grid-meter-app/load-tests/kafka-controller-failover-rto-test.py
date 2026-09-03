#!/usr/bin/env python3
"""Controlled retest of Chat's "was the killed broker also the active KRaft controller"
hypothesis for the unexplained Kafka RTO variance (docs/testing-strategy-ha-supplement.md:
3.7s, 14.0s, and 15.5s across 3 runs that killed the identical broker, two of them the
identical partition too -- ruling out "different broker/partition" as the explanation).

Hypothesis: a partition-leader-only failover is a simple reassignment among brokers the
controller already has fresh metadata for (fast). If the killed broker was ALSO the active
controller, that failure additionally triggers controller failover -- a Raft-quorum
re-election among the 3 controller voters -- before the partition-leader election can even
proceed, plausibly explaining a multi-second gap hiding inside one measured "RTO" number.

RTO is measured from the leader's own TRACE-level controller.log (via
docker-compose.kafka-debug.yml, bring that overlay up first), tailed live with
`docker compose logs -f --since <kill-instant>`, NOT by polling `kafka-topics.sh --describe`
in a loop -- confirmed live (2026-09-02) that a single `kafka-topics.sh` invocation costs
~0.96s of JVM startup overhead, meaning a polling loop using it is bottlenecked by that cost
per iteration, not the ~0.25s sleep between iterations. That's the same category of bug as
the Postgres self-demotion investigation's whole-second `SECONDS`-builtin quantization
(docs/postgres-ha-scope.md) -- a coarse instrument masquerading as fine-grained -- just with
unpredictable per-call variance instead of fixed 1s quantization, which would have been even
harder to notice without deliberately timing a single call first.

Usage: ./kafka-controller-failover-rto-test.py [--repeats 3] [--pass-label LABEL]
Prerequisites: full stack + kafka-debug overlay up
  (docker compose -f docker-compose.yml -f docker-compose.kafka-debug.yml up -d),
readings topic with 3 partitions / RF 3 already provisioned by the API.
Restores all 3 brokers before exiting, including on error/interrupt.

Archival note (2026-09-04): every output filename below is namespaced by --pass-label
(default: a UTC timestamp) after this script's own evidence-archival discipline was found to
have a real gap -- the original version used a fixed filename scheme with no pass identifier
at all, so re-running it a second time (to capture the elapsed-time diagnostic that closed out
docs/testing-strategy-ha-supplement.md's own "~250ms overclaim" correction) silently overwrote
the first corrected pass's raw controller.log slices and results JSON with the second pass's
data. That first pass's numbers survive only as a quoted terminal transcript in that doc's
prose -- not as independently re-checkable raw evidence -- and can't be recovered at this
point. This fix doesn't change that; it only guarantees every future invocation gets its own
non-colliding, fully-archived evidence set going forward, the same way the pilot/pilot2/BUGGY/
CONTAMINATED runs already preserved in results/ happened to survive only because each one's
name was manually varied by hand at the time.
"""
import argparse
import json
import re
import subprocess
import sys
import time
from datetime import datetime, timezone

COMPOSE = ["docker", "compose"]
ALL_BROKERS = [1, 2, 3]
TOPIC = "readings"
LOG_WAIT_TIMEOUT_S = 30
LOG_FILES = ["controller.log", "state-change.log"]
KAFKA_TS_RE = re.compile(r"^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\]")


def run(args, check=True, capture=True):
    return subprocess.run(args, capture_output=capture, text=True, check=check)


def kexec(broker, *cmd, check=False):
    return run(COMPOSE + ["exec", "-T", f"kafka-{broker}"] + list(cmd), check=check)


def get_controller():
    """Tries every broker, not just kafka-1 -- found live (2026-09-02) that hardcoding the
    query target breaks exactly when kafka-1 is the broker just killed, the same "monitoring
    helper's own hardcoded query target" bug shape already named in
    docs/testing-strategy-ha-supplement.md's Scenario 1 fix writeup."""
    last_err = ""
    for broker in ALL_BROKERS:
        r = kexec(broker, "/opt/kafka/bin/kafka-metadata-quorum.sh", "--bootstrap-server",
                   "localhost:9092", "describe", "--status")
        if r.returncode == 0:
            m = re.search(r"LeaderId:\s*(\d+)", r.stdout)
            if m:
                return int(m.group(1))
        last_err = r.stdout + r.stderr
    raise RuntimeError(f"Could not determine controller from any broker:\n{last_err}")


def get_partition_leaders():
    """Returns ({partition: leader_broker_id}, {partition: isr_list}) for the readings topic."""
    last_err = None
    for broker in ALL_BROKERS:
        r = kexec(broker, "/opt/kafka/bin/kafka-topics.sh", "--bootstrap-server", "localhost:9092",
                   "--describe", "--topic", TOPIC)
        if r.returncode == 0 and r.stdout.strip():
            leaders, isrs = {}, {}
            for line in r.stdout.splitlines():
                m = re.search(r"Partition:\s*(\d+)\s+Leader:\s*(-?\d+).*Isr:\s*([\d,]+)", line)
                if m:
                    leaders[int(m.group(1))] = int(m.group(2))
                    isrs[int(m.group(1))] = [int(x) for x in m.group(3).split(",")]
            if leaders:
                return leaders, isrs
        last_err = r.stdout + r.stderr
    raise RuntimeError(f"Could not read partition leaders from any broker:\n{last_err}")


def find_target(condition, controller_id, leaders):
    for partition, leader in leaders.items():
        is_controller_led = (leader == controller_id)
        if condition == "controller" and is_controller_led:
            return partition, leader
        if condition == "non-controller" and not is_controller_led and leader != -1:
            return partition, leader
    return None, None


def nudge_toward_condition(condition, controller_id, leaders):
    """No direct API to force a specific broker to lead a specific partition without a
    heavier partition-reassignment operation, so when neither condition is currently
    satisfiable, restart whichever broker currently leads the most partitions -- confirmed
    live to reliably reshuffle leadership when tried while scoping this script."""
    counts = {}
    for leader in leaders.values():
        counts[leader] = counts.get(leader, 0) + 1
    if not counts:
        return
    monopolist = max(counts, key=lambda b: counts[b])
    print(f"    (no partition currently satisfies '{condition}' -- restarting kafka-{monopolist} "
          f"to force re-election)")
    run(COMPOSE + ["restart", f"kafka-{monopolist}"], check=True)
    time.sleep(12)


def wait_for_target(condition, retries=6):
    for attempt in range(retries):
        try:
            controller_id = get_controller()
            leaders, isrs = get_partition_leaders()
        except RuntimeError:
            time.sleep(3)
            continue
        partition, leader = find_target(condition, controller_id, leaders)
        if partition is not None:
            return partition, leader, controller_id, leaders, isrs
        nudge_toward_condition(condition, controller_id, leaders)
    raise RuntimeError(f"Could not achieve condition '{condition}' after {retries} attempts")


def get_log_size(broker, filename="controller.log"):
    r = kexec(broker, "wc", "-c", f"/opt/kafka/logs/{filename}")
    m = re.match(r"\s*(\d+)", r.stdout)
    return int(m.group(1)) if m and r.returncode == 0 else 0


def start_log_tail(broker, out_path):
    """Tails controller.log starting from its CURRENT size, not byte 1 -- `tail -f` has no
    timestamp filter, so following from the start of the file would dump this whole debug
    session's accumulated history (confirmed the file can already hold thousands of lines
    from earlier trials) before ever reaching live content."""
    offset = get_log_size(broker)
    f = open(out_path, "w")
    proc = subprocess.Popen(
        COMPOSE + ["exec", "-T", f"kafka-{broker}", "tail", "-c", f"+{offset + 1}", "-f",
                   "/opt/kafka/logs/controller.log"],
        stdout=f, stderr=subprocess.DEVNULL,
    )
    return proc, f


def wait_for_leader_change_in_logs(tail_paths, partition, old_leader, kill_dt, timeout_s=LOG_WAIT_TIMEOUT_S):
    """Polls the tailed controller.log files (cheap in-process file reads, no subprocess
    spawn per check -- the whole point of this rewrite) for the specific partition-change
    line recording a new leader for our target partition. Returns (new_leader, rto_seconds,
    matched_line) or (None, None, None) on timeout.

    Re-scans each file's FULL current content every poll rather than tracking a per-file
    "lines already seen" count -- a line read while only partially flushed (no trailing
    newline yet) would otherwise get marked seen at that byte range and never re-checked
    once genuinely complete a moment later. Cheap to re-scan given these are small
    single-trial log slices, not the whole debug session's history."""
    pattern = re.compile(
        rf"partition change for readings-{partition}\b.*leader:\s*{old_leader}\s*->\s*(\d+)"
    )
    start = time.time()
    while time.time() - start < timeout_s:
        for broker, path in tail_paths.items():
            try:
                with open(path) as f:
                    text = f.read()
            except FileNotFoundError:
                continue
            m = pattern.search(text)
            if m:
                line = next((l for l in text.splitlines() if m.group(0) in l), m.group(0))
                ts_m = KAFKA_TS_RE.match(line)
                if ts_m:
                    line_dt = datetime.strptime(ts_m.group(1), "%Y-%m-%d %H:%M:%S,%f").replace(
                        tzinfo=timezone.utc)
                    rto = (line_dt - kill_dt).total_seconds()
                else:
                    rto = None
                return int(m.group(1)), rto, line.strip()
        time.sleep(0.05)
    return None, None, None


def wait_for_full_health(timeout_s=60):
    start = time.time()
    while time.time() - start < timeout_s:
        try:
            _, isrs = get_partition_leaders()
            if all(len(isr) == 3 for isr in isrs.values()) and len(isrs) == 3:
                return True
        except RuntimeError:
            pass
        time.sleep(2)
    return False


def run_trial(condition, run_num, pass_label):
    partition, leader, controller_id, leaders, isrs = wait_for_target(condition)
    is_controller_led = (leader == controller_id)
    print(f"  Target: partition {partition}, leader=kafka-{leader}, controller=kafka-{controller_id} "
          f"(is_controller={is_controller_led}) | full leader map: {leaders}")

    surviving = [b for b in ALL_BROKERS if b != leader]

    tail_paths = {}
    tail_procs = []
    for b in surviving:
        path = f"results/kafka-{pass_label}-{condition}-run{run_num}-kafka{b}-controller.log"
        proc, f = start_log_tail(b, path)
        tail_procs.append((proc, f))
        tail_paths[b] = path
    time.sleep(0.3)  # let tails actually attach before the kill

    # BUG FOUND AND FIXED (2026-09-02, via a Chat review that correctly refused to accept
    # "topology variance" as an explanation for kafka-partition-rto.py's production runs
    # measuring ~0.1s against this script's own ~0.6s): kill_dt used to be captured via
    # now_iso() BEFORE starting the tail processes above and before the time.sleep(0.3),
    # while THIS kill_wall_time (captured immediately before the real `docker compose stop`)
    # was computed correctly but only ever used for the secondary external_confirm_s metric.
    # wait_for_leader_change_in_logs() was being passed the EARLY, wrong timestamp for the
    # PRIMARY rto_s metric -- confirmed by direct instrumentation (not an isolated-component
    # estimate) that the real gap between the old capture point and this one is 0.471-0.483s
    # across 6 trials, matching the ~0.46-0.55s per-run difference between the old buggy bands
    # and the corrected ones in docs/testing-strategy-ha-supplement.md almost exactly. This is
    # the same category of bug as the JVM-per-call polling-cost finding this whole script
    # exists to fix, just one level subtler: not a slow call inside the measurement loop, but a
    # clock started before the thing being measured actually began.
    kill_wall_time = time.time()
    kill_dt = datetime.fromtimestamp(kill_wall_time, tz=timezone.utc)
    run(COMPOSE + ["stop", f"kafka-{leader}"], check=True)

    new_leader, rto_s, matched_line = wait_for_leader_change_in_logs(
        tail_paths, partition, leader, kill_dt
    )
    external_confirm_s = None
    if new_leader is not None:
        # One-shot confirmation via the client-visible view, not looped -- reports how far
        # behind the client-observable state trails the controller's own internal decision,
        # same "internal decision vs external observability" distinction the Postgres
        # self-demotion investigation drew out explicitly.
        t0 = time.time()
        try:
            leaders_after, _ = get_partition_leaders()
            if leaders_after.get(partition) == new_leader:
                external_confirm_s = time.time() - kill_wall_time
        except RuntimeError:
            pass

    time.sleep(2)  # capture a bit more post-event context before stopping tails
    for proc, f in tail_procs:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
        f.close()

    new_controller_id = None
    try:
        new_controller_id = get_controller()
    except RuntimeError:
        pass

    print(f"  -> new_leader=kafka-{new_leader} rto={round(rto_s,3) if rto_s is not None else None}s "
          f"external_confirm={round(external_confirm_s,3) if external_confirm_s else None}s "
          f"new_controller=kafka-{new_controller_id}")
    if matched_line:
        print(f"  -> matched line: {matched_line[:180]}")

    run(COMPOSE + ["start", f"kafka-{leader}"], check=True)
    healthy = wait_for_full_health()

    return {
        "condition": condition,
        "run": run_num,
        "partition": partition,
        "killed_broker": leader,
        "old_controller": controller_id,
        "was_controller": is_controller_led,
        "new_leader": new_leader,
        "new_controller": new_controller_id,
        "rto_s": round(rto_s, 3) if rto_s is not None else None,
        "external_confirm_s": round(external_confirm_s, 3) if external_confirm_s else None,
        "quorum_healthy_after": healthy,
        "matched_line": matched_line,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--repeats", type=int, default=3)
    parser.add_argument("--conditions", default="controller,non-controller")
    parser.add_argument(
        "--pass-label",
        default=None,
        help="Namespaces every output filename for this invocation (per-trial controller.log "
             "slices and the results JSON) so repeat runs never silently collide/overwrite "
             "each other's archived evidence. Defaults to a UTC timestamp if not given -- "
             "explicit only when you want a human-readable label instead.",
    )
    args = parser.parse_args()
    pass_label = args.pass_label or datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    print(f"Archiving this pass's evidence under label: {pass_label}")

    results = []
    try:
        for condition in args.conditions.split(","):
            for i in range(1, args.repeats + 1):
                print(f"\n=== Trial: condition={condition} run={i}/{args.repeats} ===")
                result = run_trial(condition, i, pass_label)
                results.append(result)
                if not result["quorum_healthy_after"]:
                    print("WARNING: full ISR not restored before timeout -- extra settle pause",
                          file=sys.stderr)
                    time.sleep(15)
                else:
                    time.sleep(5)
    finally:
        run(COMPOSE + ["start"] + [f"kafka-{b}" for b in ALL_BROKERS], check=False)

    print("\n=== Summary ===")
    for r in results:
        print(f"  [{r['condition']:>14}] run {r['run']}: killed=kafka-{r['killed_broker']} "
              f"was_controller={r['was_controller']} rto={r['rto_s']}s "
              f"external_confirm={r['external_confirm_s']}s new_controller=kafka-{r['new_controller']}")

    results_path = f"results/kafka-controller-failover-rto-results-{pass_label}.json"
    with open(results_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nFull results written to {results_path}")


if __name__ == "__main__":
    main()
