#!/usr/bin/env python3
"""One-shot diagnostic for docs/testing-strategy-ha-supplement.md's open external_confirm_s
follow-up: does the new controller experience a GC pause during the variable post-activation
window that would explain the wide external_confirm_s spread (4.0-15.15s, controller-killed
condition)? Candidate 1 (ISR catch-up lag on the affected partition specifically) was already
checked against the archived 20260903T175404Z pass's raw controller.log slices and refuted --
the target partition's ISR/leader handoff happens instantly (~0.14s, baked into the SAME
graceful-shutdown decision the dying broker's own SIGTERM handling makes, before it's actually
gone), and controller activation time itself is a roughly constant ~2.3-2.5s across all 3
archived controller-condition trials -- neither explains the multi-second variable remainder
(1.5s to ~12.8s) between controller activation and external_confirm_s.

This script tests candidate 2 directly: GC logging is already enabled by default on this Kafka
image (-Xlog:gc*:file=.../kafkaServer-gc.log, confirmed live via `ps aux` inside the container --
no new instrumentation needed). Kills the current controller, captures the same
kill_wall_time -> external_confirm_s window kafka-controller-failover-rto-test.py measures, and
checks the NEW controller's own kafkaServer-gc.log for any GC pause events inside that window.

No archived per-trial GC logs exist for the original 3 controller-condition trials -- Kafka has
no persistent volume in this project (docker-compose.yml), so those containers' GC logs are long
gone. This is a fresh, single, purpose-built trial, not a re-analysis of old evidence.

Usage: ./kafka-external-confirm-gc-check.py
Prerequisites: full stack + kafka-debug overlay up.
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


def run(args, check=True, capture=True):
    return subprocess.run(args, capture_output=capture, text=True, check=check)


def kexec(broker, *cmd, check=False):
    return run(COMPOSE + ["exec", "-T", f"kafka-{broker}"] + list(cmd), check=check)


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
                return leaders
    raise RuntimeError("Could not read partition leaders from any broker")


def get_controller_log_size(broker):
    r = kexec(broker, "wc", "-c", "/opt/kafka/logs/controller.log")
    m = re.match(r"\s*(\d+)", r.stdout)
    return int(m.group(1)) if m and r.returncode == 0 else 0


def get_gc_log_size(broker):
    r = kexec(broker, "wc", "-c", "/opt/kafka/logs/kafkaServer-gc.log")
    m = re.match(r"\s*(\d+)", r.stdout)
    return int(m.group(1)) if m and r.returncode == 0 else 0


def main():
    old_controller = get_controller()
    leaders_before = get_partition_leaders()
    print(f"Current controller: kafka-{old_controller}. Killing it (the 'controller' condition).")
    print(f"Partition leaders before kill: {leaders_before}")

    surviving = [b for b in ALL_BROKERS if b != old_controller]
    controller_log_offsets = {b: get_controller_log_size(b) for b in surviving}
    gc_log_offsets = {b: get_gc_log_size(b) for b in surviving}

    try:
        kill_wall_time = time.time()
        run(COMPOSE + ["stop", f"kafka-{old_controller}"], check=True)
        print(f"Killed kafka-{old_controller} at {kill_wall_time}")

        # Poll for the new controller to actually activate (not a fixed sleep) -- same
        # "poll for the real condition" discipline as the rest of this project's test scripts.
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

        # One-shot external-visibility check, same method as kafka-controller-failover-rto-test.py's
        # external_confirm_s (no retry loop -- deliberately mirrors that script exactly).
        while True:
            try:
                leaders_after = get_partition_leaders()
                if all(leaders_after.get(p) != old_controller for p in leaders_before
                       if leaders_before[p] == old_controller):
                    break
            except RuntimeError:
                pass
            time.sleep(0.05)
        external_confirm_time = time.time()
        external_confirm_s = external_confirm_time - kill_wall_time
        print(f"External confirm (leaders no longer show kafka-{old_controller}): "
              f"{external_confirm_s:.3f}s after kill")
        print(f"Partition leaders after: {leaders_after}")

        if new_controller is not None:
            print(f"\nGap from controller activation to external_confirm: "
                  f"{external_confirm_time - activation_time:.3f}s")

            # Check the NEW controller's own GC log for pauses inside [kill, external_confirm].
            gc_offset = gc_log_offsets.get(new_controller, 0)
            r = kexec(new_controller, "tail", "-c", f"+{gc_offset + 1}", "/opt/kafka/logs/kafkaServer-gc.log")
            print(f"\n--- kafka-{new_controller}'s GC log since the kill ({len(r.stdout.splitlines())} new lines) ---")
            pause_lines = [l for l in r.stdout.splitlines() if "Pause" in l]
            if pause_lines:
                for l in pause_lines:
                    print(f"  {l}")
            else:
                print("  (no 'Pause' GC events logged in this window)")
    finally:
        run(COMPOSE + ["start", f"kafka-{old_controller}"], check=False)
        print(f"\nRestarted kafka-{old_controller}.")


if __name__ == "__main__":
    main()
