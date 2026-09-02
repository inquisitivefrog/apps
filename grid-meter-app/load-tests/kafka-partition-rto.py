#!/usr/bin/env python3
"""Measures real Kafka partition-leader-election RTO by tailing the surviving brokers'
TRACE-level controller.log for the actual leader-change decision, instead of polling
`kafka-topics.sh --describe` in a loop.

Why this exists: timed directly (2026-09-02, see docs/testing-strategy-ha-supplement.md's
"RTO variance retest"), a single `kafka-topics.sh --describe` invocation costs ~0.96s,
almost entirely JVM startup -- a polling loop calling it every ~0.5s therefore actually
polls at roughly a 1.5s cadence, not 0.5s, and the resulting "RTO" numbers mostly reflect
how many ~1.5s-costly iterations it took to notice the change, not a real measurement of
Kafka's own election time. This tool reads the controller's own internal decision timestamp
directly instead, eliminating that per-call cost from the measurement entirely.

REQUIRES the kafka-debug overlay to be active (docker-compose.kafka-debug.yml), which raises
org.apache.kafka.controller to at least DEBUG level -- confirmed live that the specific line
this tool matches on is logged at DEBUG, not TRACE, so the overlay's full TRACE-everything
verbosity is not required for this specifically, just a config that includes at least DEBUG
for that one logger. Exits with a clear error if that logging isn't active rather than
silently falling back to the imprecise polling method this tool exists to replace.

Usage:
  kafka-partition-rto.py <partition> <old_leader_broker_id> <signal_file> [--timeout SECONDS]

Protocol: start this tool BEFORE killing the target broker (it needs a moment to snapshot
log offsets and attach its tails). Once the actual kill happens, write the kill instant as
an ISO 8601 UTC timestamp into <signal_file> (e.g.
`python3 -c "from datetime import datetime, timezone; print(datetime.now(timezone.utc).isoformat())" > "$SIGNAL_FILE"`
-- deliberately not bash `date +%3N`, which silently misparses on this Mac's BSD `date`;
see docs/testing-strategy.md's GNU-vs-BSD lesson). This tool waits for both the signal file
and a matching log line (in either order) before computing RTO, so exact timing between
starting this tool and performing the kill doesn't need to be tightly synchronized.

Prints "<new_leader_broker_id> <rto_seconds>" to stdout on success, "NONE 0" on timeout, and
exits 1 on timeout so callers can distinguish a real "no leader elected" finding from a
successful measurement without parsing output.
"""
import argparse
import re
import subprocess
import sys
import time
from datetime import datetime, timezone

COMPOSE = ["docker", "compose"]
ALL_BROKERS = [1, 2, 3]
TOPIC = "readings"
KAFKA_TS_RE = re.compile(r"^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3})\]")


def run(args, check=False, capture=True):
    return subprocess.run(args, capture_output=capture, text=True, check=check)


def kexec(broker, *cmd):
    return run(COMPOSE + ["exec", "-T", f"kafka-{broker}"] + list(cmd))


def check_debug_logging_active(broker):
    r = kexec(broker, "cat", "/opt/kafka/config/log4j2.yaml")
    if r.returncode != 0:
        return False
    text = r.stdout
    # Looking for org.apache.kafka.controller raised above the stock ERROR/INFO root level --
    # DEBUG or TRACE both work, since the line this tool needs is logged at DEBUG.
    m = re.search(r'name:\s*"org\.apache\.kafka\.controller"\s*\n\s*level:\s*"(DEBUG|TRACE)"', text)
    return bool(m)


def get_log_size(broker, filename="controller.log"):
    r = kexec(broker, "wc", "-c", f"/opt/kafka/logs/{filename}")
    m = re.match(r"\s*(\d+)", r.stdout)
    return int(m.group(1)) if m and r.returncode == 0 else 0


def start_log_tail(broker, out_path):
    """Redirects the tail to a file rather than a pipe read in the polling loop below --
    `Popen.stdout.readline()` on a pipe BLOCKS until a line arrives or the process ends,
    which would stall the loop indefinitely on whichever broker happens to have nothing new
    to say yet, never reaching the other broker's pipe or the timeout check. Re-reading a
    file's current contents each poll never blocks, at the cost of re-scanning a small
    amount of already-seen text each iteration -- cheap for these short single-trial slices."""
    offset = get_log_size(broker)
    f = open(out_path, "w")
    proc = subprocess.Popen(
        COMPOSE + ["exec", "-T", f"kafka-{broker}", "tail", "-c", f"+{offset + 1}", "-f",
                   "/opt/kafka/logs/controller.log"],
        stdout=f, stderr=subprocess.DEVNULL,
    )
    return proc, f


def read_signal(signal_file):
    try:
        with open(signal_file) as f:
            content = f.read().strip()
        if content:
            return datetime.fromisoformat(content)
    except (FileNotFoundError, ValueError):
        pass
    return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("partition", type=int)
    parser.add_argument("old_leader", type=int)
    parser.add_argument("signal_file")
    parser.add_argument("--timeout", type=float, default=30.0)
    args = parser.parse_args()

    survivors = [b for b in ALL_BROKERS if b != args.old_leader]
    if not check_debug_logging_active(survivors[0]):
        print(
            "ERROR: kafka-debug overlay does not appear active (org.apache.kafka.controller "
            "is not at DEBUG/TRACE). Bring it up first:\n"
            "  docker compose -f docker-compose.yml -f docker-compose.kafka-debug.yml up -d\n"
            "This is required for real RTO measurement -- see docs/testing-strategy-ha-supplement.md's "
            "\"RTO variance retest\" for why the old kafka-topics.sh polling method is not trustworthy.",
            file=sys.stderr,
        )
        sys.exit(2)

    tail_paths = {b: f"/tmp/kafka-partition-rto-tail-kafka{b}-{args.partition}.log" for b in survivors}
    tails = {b: start_log_tail(b, tail_paths[b]) for b in survivors}
    pattern = re.compile(
        rf"partition change for {TOPIC}-{args.partition}\b.*leader:\s*{args.old_leader}\s*->\s*(\d+)"
    )

    kill_dt = None
    start = time.time()
    result = None
    matched_line = None
    try:
        while time.time() - start < args.timeout:
            if kill_dt is None:
                kill_dt = read_signal(args.signal_file)

            for b, path in tail_paths.items():
                try:
                    with open(path) as f:
                        text = f.read()
                except FileNotFoundError:
                    continue
                m = pattern.search(text)
                if m and kill_dt is not None:
                    line = next((l for l in text.splitlines() if m.group(0) in l), m.group(0))
                    ts_m = KAFKA_TS_RE.match(line)
                    rto = None
                    if ts_m:
                        line_dt = datetime.strptime(ts_m.group(1), "%Y-%m-%d %H:%M:%S,%f").replace(
                            tzinfo=timezone.utc)
                        rto = (line_dt - kill_dt).total_seconds()
                    result = (int(m.group(1)), rto)
                    matched_line = line
                    break
            if result:
                break
            time.sleep(0.05)
    finally:
        for proc, f in tails.values():
            proc.terminate()
            f.close()

    if result and result[1] is not None:
        if matched_line:
            print(f"matched: {matched_line}", file=sys.stderr)
        print(f"{result[0]} {round(result[1], 3)}")
        sys.exit(0)
    else:
        print("NONE 0")
        sys.exit(1)


if __name__ == "__main__":
    main()
