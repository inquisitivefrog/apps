# 2026-10-08 — No-op safety, a real syntax bug caught by actually running it, EventBridge replaces GitHub's scheduler

## Done

- **Fixed a real false-positive bug in yesterday's "no-op if already up/empty" check**: `terraform
  output -raw <name>` on an output that doesn't exist leaks a multi-line "Warning: No outputs
  found" onto **stdout** (not stderr) on Terraform 1.13.2 (CI's pinned version) - a `2>/dev/null`
  guard never catches it, so the warning text itself got captured as a "truthy" value, causing
  both the real scheduled run and a manual re-trigger to silently no-op without ever deploying
  anything. Root cause only surfaced because this Mac's local Terraform had silently drifted to
  1.16.4 (doesn't reproduce the leak) via an unrelated earlier Terraform project's `brew upgrade`
  - confirmed live via an isolated `bash -n`/`bash -c` reproduction, not assumed. Fixed by parsing
    `terraform output -json` structurally (via python3) instead of trusting `-raw`'s stdout to
    only ever contain the value, in both workflows' `check` jobs.
- **Terraform pinned to `~> 1.13.0`** (not an exact pin - a minor-version lock, since the bug was
  a minor-version behavior change and HashiCorp treats patches as bug-fix-only) in both
  `terraform/aws/versions.tf` and `bootstrap-freetier/versions.tf`, documented in
  `docs/tech-stack-versions.md` (previously undocumented there despite every other pinned tool
  having an entry). `tfenv` set up locally (`brew unlink terraform` + `brew link --overwrite
  tfenv` to resolve a real conflict over `/opt/homebrew/bin/terraform`), `.terraform-version`
  files added so it auto-switches to 1.13.2 per directory, matching CI exactly.
- **Found and fixed a real, previously-undetected bash syntax error** in the "Seed meter status
  variety" step: `TOKEN="$(curl ... | python3 -c '...')` was missing its closing double quote.
  This step had **never actually executed in any CI run** - Run #8/#9/#10 all failed earlier
  (rapid-spike/ramp-up) before reaching it, Run #11 no-op'd on the bug above, Run #12 hung
  installing JMeter - so the bug was masked by upstream failures the whole time. Found by manually
  replicating the step locally against the live deployment (after a hung Run #12 was cancelled)
  and hitting the real error; fixed, verified via `bash -n` on the actual extracted YAML content,
  and proactively syntax-checked every other `run:` block in both workflow files (all clean - this
  was the only one). Verified live: created 6 meters (3 INACTIVE, 3 MAINTENANCE) with no errors.
- **Scaled back the daily ramp-up/rapid-spike load tests** from "tuned right at this
  architecture's ceiling" to "comfortably below any observed failure point" - three consecutive
  runs (#8/#9/#10) each failed differently (boundary-exact p95, an error burst, a 695ms blowout)
  at parameters tuned to the edge, and the ceiling itself drifted run-to-run under repeated
  same-day cycles. Investigated and ruled out CPU-credit exhaustion as the cause (confirmed live:
  EC2 nodes run in `unlimited` credit mode via `describe-instance-credit-specifications`; RDS
  t3/t4g classes always run unlimited, no throttling mode exists for them at all; both RDS and
  Kafka's PVCs use `gp3`, not `gp2`, so no EBS burst-credit mechanism either) - real cause remains
  open (likely lower-level shared-infrastructure variance), but the fix (back off well below any
  observed ceiling) doesn't depend on knowing the exact mechanism. Re-scoped these three steps as
  "demo traffic flavor" (not a genuine capacity test - that's `grid-meter-app-load-test.yml`'s
  job) per explicit instruction.
- **EventBridge now replaces GitHub Actions' own `schedule:` trigger for both workflows.**
  GitHub's native scheduler showed a consistent, repeatable ~6-7hr dispatch lag on this repo
  (confirmed against weeks of `grid-meter-app-load-test.yml` history, and reproduced live on both
  `aws-startup` and `aws-teardown` the same day) - a documented, widely-reported platform
  characteristic (GitHub community discussion found describing an 8-14hr case on another repo,
  nearly identical shape), not fixable from this repo's side, and not viable to work around with a
  local cron job since this Mac can't be guaranteed always-on.
  - Built via `terraform/aws/bootstrap-freetier/eventbridge-scheduler.tf`: an EventBridge
    Connection (holds a repo-scoped, Actions-only fine-grained GitHub PAT, set via
    `TF_VAR_github_pat` - never pasted to Claude), two API Destinations (one per workflow's
    dispatch URL), and - after a real failed-apply correction (`aws_scheduler_schedule` does NOT
    support API Destinations as a target at all; that's an EventBridge *Rules* feature instead,
    confirmed against AWS's own docs) - `aws_cloudwatch_event_rule`/`_target` pairs.
  - IAM: added a small, tightly-scoped statement to the human's `grid-meter-app-terraform` policy
    (`scheduler:*`/`events:*`, `Resource: "*"`) - had to trim twice to fit IAM's 6144-character
    customer-managed-policy limit (first by removing two statements made fully redundant by the
    existing `IamScopedToProjectResources` grant, then by widening to service wildcards).
  - **Validated via two one-time near-term test rules before committing to the permanent daily
    times**: both fired within ~15-20 seconds of their scheduled time (20:10:17 vs 20:10:00 UTC
    for startup, 21:00:15 vs 21:00:00 UTC for teardown) - versus GitHub's observed ~6-7hr delay.
    The startup test was also **the first-ever fully green run of the complete pipeline** with
    every fix from today in place (no-op check, scaled-back load tests, the syntax-fixed seeding
    step), not just individually-verified pieces - 39m38s, every step passed. Teardown test also
    fully green, 14m13s.
  - Converted to the permanent daily schedule immediately after: `cron(0 11 * * ? *)` /
    `cron(0 1 * * ? *)` (11:00 UTC / 01:00 UTC, same times GitHub's own trigger was configured
    for) - confirmed live via `aws events describe-rule`, both `ENABLED`.
- **Interview-access question resolved**: considered a separate read-only account for
  interviewers vs. sharing the seeded `demo` account directly. Checked the actual code
  (`AuthUserDetailsService.java`, `JwtAuthenticationFilter.java`) - confirmed this app has no
  role-based access control at all (every authenticated user gets a hardcoded `ROLE_USER`), so a
  second account wouldn't actually be read-only - it would have identical permissions. Decided to
  share the single `demo` account as-is: the nightly full rebuild already self-heals any changes
  within 24 hours (not originally built for this reason, but covers it), and readings are
  immutable by design already (no `PUT /readings/{id}`, read-only UI). Real RBAC would be a scope
  expansion this project has deliberately avoided everywhere else.

## Current live state (as of session end)

- Everything torn down (last teardown test, 21:00 UTC). Nothing billing.
- EventBridge's permanent daily schedule is live and `ENABLED` - next real validation is
  tomorrow's unattended 11:00 UTC / ~4am PDT firing, with no workflow_dispatch from a human
  involved at all for the first time.
- Both `aws-freetier` and `main` fully in sync on all workflow-file changes (confirmed via diff
  after every push, same established pattern).
- AWS account: $154.63 of $200 credit remaining, 181 days left (expires Apr 6, 2027) - not an
  "hours" cap as originally misremembered; EventBridge Scheduler's own cost impact is negligible
  (~60 invocations/month against a 14M/month free tier).

## Open / Next

1. **Watch tomorrow's unattended 11:00 UTC firing** - first real test of the permanent schedule
   with zero manual intervention. If EventBridge's own delivery has any gap GitHub's didn't
   (lower likelihood given today's two clean tests, but unverified at daily-recurring cadence),
   this is where it'd show up.
2. The real root cause of the load-test run-to-run variance (CPU credits and EBS burst credits
   both ruled out) remains open - not blocking (the fix doesn't depend on it), but worth another
   look if it recurs and real evidence narrows it further.
3. Still not started: frontend auto-login (agreed approach for the interview-facing fixed URL,
   scoped in conversation much earlier, zero code written yet).
4. Consider whether the EventBridge Connection's GitHub PAT needs a calendar reminder before its
   expiration (set during creation today) - not tracked anywhere yet.
