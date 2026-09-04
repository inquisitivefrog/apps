#!/usr/bin/env python3
"""Third and final bounded round on docs/testing-strategy-ha-supplement.md's open
external_confirm_s follow-up (Chat, 2026-09-04): candidates 1 (ISR catch-up lag) and 2
(GC-pause noise) are both refuted (see kafka-controller-failover-rto-test.py's archived
evidence and kafka-external-confirm-gc-check.py respectively). This checks the one remaining
plausible, unchased lead named at the time: AdminClient's own internal retry/backoff behavior
inside the single `kafka-topics.sh --describe` call itself -- a client-side cost that would
produce a multi-second gap with zero broker-side (GC or ISR) signature, the same shape this
investigation has already found twice (JVM-spawn cost, then an early-clock bug) wearing a
Kafka-mechanism costume.

Mechanism: overrides KAFKA_LOG4J_OPTS to point kafka-topics.sh at a temporary log4j2 config
enabling DEBUG logging for org.apache.kafka.clients (confirmed live this logs every
connection/request/retry the AdminClient makes, correlationId-tagged, millisecond-timestamped)
-- no source change, no new server-side instrumentation, just reading the client's own existing
logging capability.

Usage: ./kafka-external-confirm-adminclient-check.py
Prerequisites: full stack + kafka-debug overlay up, readings topic provisioned (3 partitions,
RF 3).
Restores the killed broker before exiting, including on error/interrupt.
"""
import re
import subprocess
import sys
import time
from datetime import datetime, timezone

COMPOSE = ["docker", "compose"]
ALL_BROKERS = [1, 2, 3]
TOPIC = "readings"
DEBUG_LOG4J_CONFIG = "/tmp/debug-log4j2.yaml"
DEBUG_LOG4J_YAML = """Configuration:
  Properties:
    Property:
    - name: "logPattern"
      value: "[%d{yyyy-MM-dd HH:mm:ss,SSS}] %p %m (%c)%n"
  Appenders:
    Console:
      name: "STDERR"
      target: "SYSTEM_ERR"
      PatternLayout:
        pattern: "${logPattern}"
  Loggers:
    Logger:
    - name: "org.apache.kafka.clients"
      level: "DEBUG"
      additivity: false
      AppenderRef:
      - ref: "STDERR"
    Root:
      level: "WARN"
      AppenderRef:
      - ref: "STDERR"
"""


def run(args, check=True, capture=True):
    return subprocess.run(args, capture_output=capture, text=True, check=check)


def kexec(broker, *cmd, check=False, env=None):
    full_cmd = COMPOSE + ["exec", "-T"]
    if env:
        for k, v in env.items():
            full_cmd += ["-e", f"{k}={v}"]
    full_cmd += [f"kafka-{broker}"] + list(cmd)
    return run(full_cmd, check=check)


def install_debug_log4j(broker):
    run(COMPOSE + ["exec", "-T", f"kafka-{broker}", "sh", "-c",
                    f"cat > {DEBUG_LOG4J_CONFIG} << 'EOF'\n{DEBUG_LOG4J_YAML}EOF"], check=True)


def get_controller():
    for broker in ALL_BROKERS:
        r = kexec(broker, "/opt/kafka/bin/kafka-metadata-quorum.sh", "--bootstrap-server",
                   "localhost:9092", "describe", "--status")
        if r.returncode == 0:
            m = re.search(r"LeaderId:\s*(\d+)", r.stdout)
            if m:
                return int(m.group(1))
    raise RuntimeError("Could not determine controller from any broker")


def get_partition_leaders():
    for broker in ALL_BROKERS:
        r = kexec(broker, "/opt/kafka/bin/kafka-topics.sh", "--bootstrap-server", "localhost:9092",
                   "--describe", "--topic", TOPIC)
        if r.returncode == 0 and r.stdout.strip():
            leaders = {}
            for line in r.stdout.splitlines():
                m = re.search(r"Partition:\s*(\d+)\s+Leader:\s*(-?\d+)", line)
                if m:
                    leaders[int(m.group(1))] = int(m.group(2))
            if leaders:
                return leaders, broker
    raise RuntimeError("Could not read partition leaders from any broker")


def get_controller_log_size(broker):
    r = kexec(broker, "wc", "-c", "/opt/kafka/logs/controller.log")
    m = re.match(r"\s*(\d+)", r.stdout)
    return int(m.group(1)) if m and r.returncode == 0 else 0


def main():
    old_controller = get_controller()
    leaders_before, _ = get_partition_leaders()
    print(f"Current controller: kafka-{old_controller}. Killing it (the 'controller' condition).")
    print(f"Partition leaders before kill: {leaders_before}")

    surviving = [b for b in ALL_BROKERS if b != old_controller]
    controller_log_offsets = {b: get_controller_log_size(b) for b in surviving}
    for b in surviving:
        install_debug_log4j(b)

    try:
        kill_wall_time = time.time()
        run(COMPOSE + ["stop", f"kafka-{old_controller}"], check=True)
        print(f"Killed kafka-{old_controller} at {kill_wall_time}")

        new_controller = None
        activation_time = None
        deadline = time.time() + 30
        while time.time() < deadline:
            for b in surviving:
                r = kexec(b, "tail", "-c", f"+{controller_log_offsets[b] + 1}", "/opt/kafka/logs/controller.log")
                if r.returncode != 0:
                    continue
                m = re.search(
                    r"\[([\d-]+ [\d:,]+)\] INFO \[QuorumController id=(\d+)\] Becoming the active controller",
                    r.stdout,
                )
                if m:
                    ts = datetime.strptime(m.group(1), "%Y-%m-%d %H:%M:%S,%f").replace(tzinfo=timezone.utc)
                    new_controller = int(m.group(2))
                    activation_time = ts.timestamp()
                    break
            if new_controller is not None:
                break
            time.sleep(0.5)

        if new_controller is None:
            print("WARNING: never observed 'Becoming the active controller' within 30s", file=sys.stderr)
        else:
            print(f"New controller kafka-{new_controller} activated at {activation_time} "
                  f"({activation_time - kill_wall_time:.3f}s after kill)")

        # THE key call: one-shot external-visibility check, same method as the original
        # investigation script and the GC check, but this time with AdminClient DEBUG logging
        # enabled so its own client-side timeline (connections, retries, timeouts) is captured
        # for the full duration this single call actually takes to return.
        query_broker = surviving[0]
        t_query_start = time.time()
        r = kexec(query_broker, "/opt/kafka/bin/kafka-topics.sh", "--bootstrap-server", "localhost:9092",
                  "--describe", "--topic", TOPIC, env={"KAFKA_LOG4J_OPTS": f"-Dlog4j2.configurationFile={DEBUG_LOG4J_CONFIG}"})
        t_query_end = time.time()
        external_confirm_s = t_query_end - kill_wall_time
        query_duration_s = t_query_end - t_query_start

        print(f"\nSingle --describe call (against kafka-{query_broker}) took "
              f"{query_duration_s:.3f}s wall-clock to return.")
        print(f"External confirm (kill to this call returning): {external_confirm_s:.3f}s")
        print(f"\n--- kafka-topics.sh stdout (the actual describe output) ---")
        print(r.stdout)
        print(f"\n--- AdminClient DEBUG log (stderr, {len(r.stderr.splitlines())} lines) ---")
        print(r.stderr)
    finally:
        run(COMPOSE + ["start", f"kafka-{old_controller}"], check=False)
        print(f"\nRestarted kafka-{old_controller}.")


if __name__ == "__main__":
    main()
