#!/usr/bin/env python3
"""Polls api's own /actuator/prometheus endpoint directly (not Prometheus's own scrape, which is
15s -- far too coarse for a breaker whose minimum-number-of-calls is 10 and can plausibly open in
well under a second) at a fine interval, recording the exact metrics
docs/resilience-scope.md's sustained-concurrent-Kafka-outage test needs: Tomcat thread-pool
pressure and the kafka-publish circuit breaker's own state/call-outcome counters. Reads the same
series Prometheus itself scrapes -- this is a higher-resolution direct read of that already-scraped
source, not new instrumentation.

A single GET here costs ~10-20ms (timed directly before trusting this, per
docs/testing-strategy.md's "a polling loop's own per-call cost can dominate the measurement"
standing lesson) -- negligible against the default 0.2s interval, so this loop's stated resolution
is real, not an artifact of an expensive call hiding inside a short sleep.

Uses Python's own clock (time.time()), not bash `date`, per CLAUDE.md's standing GNU-vs-BSD
tooling note.

Usage: kafka-cb-loadtest-poller.py --duration SECONDS --out CSV_PATH [--interval SECONDS] [--url URL]
Runs for exactly --duration seconds from the moment it starts, then exits on its own -- the caller
doesn't need to signal it to stop.
"""
import argparse
import re
import time
import urllib.request

METRIC_PATTERNS = {
    "tomcat_busy": re.compile(r'^tomcat_threads_busy_threads\{name="http-nio-8080"\}\s+([0-9.]+)', re.M),
    "tomcat_max": re.compile(r'^tomcat_threads_config_max_threads\{name="http-nio-8080"\}\s+([0-9.]+)', re.M),
    "cb_closed": re.compile(r'^resilience4j_circuitbreaker_state\{name="kafka-publish",state="closed"\}\s+([0-9.]+)', re.M),
    "cb_open": re.compile(r'^resilience4j_circuitbreaker_state\{name="kafka-publish",state="open"\}\s+([0-9.]+)', re.M),
    "cb_half_open": re.compile(r'^resilience4j_circuitbreaker_state\{name="kafka-publish",state="half_open"\}\s+([0-9.]+)', re.M),
    "cb_failed_count": re.compile(r'^resilience4j_circuitbreaker_calls_seconds_count\{kind="failed",name="kafka-publish"\}\s+([0-9.]+)', re.M),
    "cb_success_count": re.compile(r'^resilience4j_circuitbreaker_calls_seconds_count\{kind="successful",name="kafka-publish"\}\s+([0-9.]+)', re.M),
    "cb_not_permitted_total": re.compile(r'^resilience4j_circuitbreaker_not_permitted_calls_total\{kind="not_permitted",name="kafka-publish"\}\s+([0-9.]+)', re.M),
}

FIELDNAMES = ["unix_time", "elapsed_s"] + list(METRIC_PATTERNS.keys()) + ["fetch_ms", "error"]


def fetch_metrics(url: str) -> dict:
    start = time.time()
    row = {}
    try:
        with urllib.request.urlopen(url, timeout=2) as resp:
            body = resp.read().decode("utf-8", errors="replace")
        for key, pattern in METRIC_PATTERNS.items():
            m = pattern.search(body)
            row[key] = m.group(1) if m else ""
        row["error"] = ""
    except Exception as exc:  # noqa: BLE001 -- a fetch failure is itself a real data point (e.g. api briefly unreachable), not fatal to the poller
        for key in METRIC_PATTERNS:
            row[key] = ""
        row["error"] = repr(exc)
    row["fetch_ms"] = round((time.time() - start) * 1000, 2)
    return row


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--duration", type=float, required=True, help="total seconds to poll for")
    parser.add_argument("--out", required=True, help="CSV output path")
    parser.add_argument("--interval", type=float, default=0.2, help="seconds between polls (default 0.2)")
    parser.add_argument("--url", default="http://localhost/actuator/prometheus")
    args = parser.parse_args()

    start = time.time()
    with open(args.out, "w") as f:
        f.write(",".join(FIELDNAMES) + "\n")
        f.flush()
        next_poll = start
        while True:
            now = time.time()
            elapsed = now - start
            if elapsed >= args.duration:
                break
            row = fetch_metrics(args.url)
            row["unix_time"] = f"{now:.3f}"
            row["elapsed_s"] = f"{elapsed:.3f}"
            f.write(",".join(str(row[k]) for k in FIELDNAMES) + "\n")
            f.flush()
            next_poll += args.interval
            sleep_for = next_poll - time.time()
            if sleep_for > 0:
                time.sleep(sleep_for)


if __name__ == "__main__":
    main()
