#!/usr/bin/env python3
"""Analyzes one kafka-circuitbreaker-loadtest.sh run: combines the high-resolution Prometheus
poller CSV (kafka-cb-loadtest-poller.py) with JMeter's own results.jtl to answer
docs/resilience-scope.md's two open questions with real measured numbers, not a pass/fail
assertion:

  (a) Does resilience4j_circuitbreaker_instances.kafka-publish open before Tomcat's thread pool
      saturates -- i.e. does tomcat_threads_busy_threads stay bounded during the window between
      the outage starting and the breaker actually opening?
  (b) Once open, does concurrent traffic actually get shed fast (sub-second elapsed time on each
      failed sample), or does something pile up?

Usage: kafka-cb-loadtest-analyze.py --jtl RESULTS.jtl --poller-csv POLLER.csv \
           --kill-iso ISO8601 --restart-iso ISO8601 [--tomcat-max 200] [--json OUT.json]
"""
import argparse
import csv
import json
import statistics
from datetime import datetime, timezone


def parse_iso(s: str) -> float:
    return datetime.fromisoformat(s.replace("Z", "+00:00")).timestamp()


def load_poller_csv(path: str) -> list[dict]:
    rows = []
    with open(path) as f:
        for row in csv.DictReader(f):
            if row.get("error"):
                continue
            try:
                rows.append({
                    "unix_time": float(row["unix_time"]),
                    "tomcat_busy": float(row["tomcat_busy"]) if row["tomcat_busy"] else None,
                    "cb_open": float(row["cb_open"]) if row["cb_open"] else None,
                    "cb_half_open": float(row["cb_half_open"]) if row["cb_half_open"] else None,
                    "cb_not_permitted_total": float(row["cb_not_permitted_total"]) if row["cb_not_permitted_total"] else None,
                    "cb_failed_count": float(row["cb_failed_count"]) if row["cb_failed_count"] else None,
                })
            except ValueError:
                continue
    rows.sort(key=lambda r: r["unix_time"])
    return rows


def pct(values: list[float], p: float) -> float:
    if not values:
        return float("nan")
    s = sorted(values)
    idx = min(len(s) - 1, int(round(p * (len(s) - 1))))
    return s[idx]


def load_jtl(path: str) -> list[dict]:
    rows = []
    with open(path) as f:
        for row in csv.DictReader(f):
            if row.get("label") != "POST /readings":
                continue
            try:
                rows.append({
                    "ts": int(row["timeStamp"]) / 1000.0,
                    "elapsed_ms": int(row["elapsed"]),
                    "code": row["responseCode"],
                    "success": row["success"] == "true",
                })
            except (ValueError, KeyError):
                continue
    rows.sort(key=lambda r: r["ts"])
    return rows


def summarize_elapsed(rows: list[dict]) -> dict:
    if not rows:
        return {"count": 0}
    elapsed = [r["elapsed_ms"] for r in rows]
    return {
        "count": len(rows),
        "min_ms": min(elapsed),
        "mean_ms": round(statistics.mean(elapsed), 1),
        "p95_ms": pct(elapsed, 0.95),
        "max_ms": max(elapsed),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--jtl", required=True)
    parser.add_argument("--poller-csv", required=True)
    parser.add_argument("--kill-iso", required=True)
    parser.add_argument("--restart-iso", required=True)
    parser.add_argument("--tomcat-max", type=float, default=200.0)
    parser.add_argument("--json", default=None)
    args = parser.parse_args()

    kill_t = parse_iso(args.kill_iso)
    restart_t = parse_iso(args.restart_iso)

    poller = load_poller_csv(args.poller_csv)
    jtl = load_jtl(args.jtl)

    # --- (a): time-to-open and pre-open thread-pool pressure ---
    open_rows = [r for r in poller if r["cb_open"] == 1.0 and r["unix_time"] >= kill_t]
    first_open_t = open_rows[0]["unix_time"] if open_rows else None
    time_to_open_s = (first_open_t - kill_t) if first_open_t else None

    ramp_window = [r for r in poller if kill_t <= r["unix_time"] < (first_open_t or restart_t)]
    ramp_busy = [r["tomcat_busy"] for r in ramp_window if r["tomcat_busy"] is not None]

    open_steady_window = [r for r in poller if (first_open_t or kill_t) <= r["unix_time"] < restart_t]
    open_steady_busy = [r["tomcat_busy"] for r in open_steady_window if r["tomcat_busy"] is not None]

    overall_busy = [r["tomcat_busy"] for r in poller if r["tomcat_busy"] is not None]

    # Count how many times cb_open transitioned 0->1 during the outage window -- each one is a
    # half-open probe cycle that failed and re-opened (expected under a sustained, still-down
    # Kafka, per wait-duration-in-open-state=10s with automatic-transition disabled).
    outage_rows = [r for r in poller if kill_t <= r["unix_time"] < restart_t and r["cb_open"] is not None]
    reopen_transitions = sum(
        1 for i in range(1, len(outage_rows))
        if outage_rows[i - 1]["cb_open"] == 0.0 and outage_rows[i]["cb_open"] == 1.0
    )

    not_permitted_in_outage = [r["cb_not_permitted_total"] for r in outage_rows if r["cb_not_permitted_total"] is not None]
    not_permitted_growth = (not_permitted_in_outage[-1] - not_permitted_in_outage[0]) if len(not_permitted_in_outage) >= 2 else None

    # --- (b): elapsed-time distribution by phase and status code, under real concurrency ---
    pre_kill = [r for r in jtl if r["ts"] < kill_t]
    during_outage = [r for r in jtl if kill_t <= r["ts"] < restart_t]
    post_recovery = [r for r in jtl if r["ts"] >= restart_t]

    during_by_code: dict[str, list[dict]] = {}
    for r in during_outage:
        during_by_code.setdefault(r["code"], []).append(r)

    report = {
        "kill_iso": args.kill_iso,
        "restart_iso": args.restart_iso,
        "tomcat_max_threads": args.tomcat_max,
        "question_a_breaker_opens_before_saturation": {
            "time_to_open_s": round(time_to_open_s, 3) if time_to_open_s is not None else None,
            "breaker_ever_opened": first_open_t is not None,
            "ramp_up_window_peak_busy_threads": max(ramp_busy) if ramp_busy else None,
            "ramp_up_window_sample_count": len(ramp_busy),
            "open_steady_state_peak_busy_threads": max(open_steady_busy) if open_steady_busy else None,
            "overall_peak_busy_threads": max(overall_busy) if overall_busy else None,
            "peak_as_pct_of_max": round(100 * max(overall_busy) / args.tomcat_max, 1) if overall_busy else None,
        },
        "question_b_fast_shedding_under_concurrency": {
            "reopen_probe_cycles_observed_during_outage": reopen_transitions,
            "not_permitted_calls_growth_during_outage": not_permitted_growth,
            "elapsed_ms_by_response_code_during_outage": {
                code: summarize_elapsed(rows) for code, rows in sorted(during_by_code.items())
            },
        },
        "phase_totals": {
            "pre_kill": summarize_elapsed(pre_kill),
            "during_outage": summarize_elapsed(during_outage),
            "post_recovery": summarize_elapsed(post_recovery),
        },
        "codes_seen": {
            "pre_kill": sorted({r["code"] for r in pre_kill}),
            "during_outage": sorted({r["code"] for r in during_outage}),
            "post_recovery": sorted({r["code"] for r in post_recovery}),
        },
        "poller_samples_total": len(poller),
        "poller_samples_with_fetch_error": None,  # filled by caller if it cares; poller CSV already drops these from load_poller_csv
    }

    text = json.dumps(report, indent=2, default=str)
    print(text)
    if args.json:
        with open(args.json, "w") as f:
            f.write(text)


if __name__ == "__main__":
    main()
