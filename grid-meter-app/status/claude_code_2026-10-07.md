# 2026-10-07 — CI/CD pipeline hardening: stable URL, load-test tuning, first teardown run

## Done

- **Resume-stable public URL solved**: the Classic ELB hostname the app got on manual launch
  was confirmed *not* stable across a full destroy/rebuild cycle — unacceptable for a URL going
  on a resume with a week+ response lag. Built a static Elastic IP + AWS Load Balancer
  Controller + NLB stack instead:
  - `terraform/aws/bootstrap-freetier/eip.tf` — a single persistent EIP (matches this project's
    already-accepted single-AZ edge-tier scope), survives every nightly destroy of the main stack.
  - `terraform/aws/load-balancer-controller.tf` + the official (unmodified, WebFetched) AWS LB
    Controller IAM policy, granted to the EC2 node role (IRSA is blocked by this account's SCP,
    same workaround already used for EBS CSI) — controller pods scheduled on the EC2 node group,
    not Fargate, so they can reach that role via IMDS.
  - `k8s/traefik-aws.yaml`'s Service annotated for `aws-load-balancer-eip-allocations` +
    `-subnets` (pinned to one subnet to match the one EIP); `deploy-aws.sh` substitutes both at
    deploy time and reports the EIP as the app's URL instead of the NLB's own ephemeral hostname.
  - **Live, resume-safe address: `http://3.149.164.41/meters`.** Confirmed by running two full
    destroy→rebuild cycles today and checking the address didn't change either time.
  - EKS access-entry collision fixed along the way: `bootstrap_cluster_creator_admin_permissions`
    creates an *implicit* entry for whichever identity's `apply` creates the cluster — collided
    with CI's own explicit entry once CI started creating clusters itself (never surfaced when a
    human always ran `apply`, since human and CI are different principals). Disabled the implicit
    grant, declared explicit access entries for both identities.
- **First-ever real CI run of the full startup pipeline, clean (Run #7)**: all steps green,
  including steady-state/ramp-up/rapid-spike load tests live-tuned against this specific
  free-tier architecture (rapid-spike's documented 600-thread default produced a genuine
  32.57% error rate here — not flaky — tuned down to 100 threads to pass cleanly standalone).
- **Historical-backfill + status-variety seeding added as daily CI steps, not one-time**: caught
  that the full nightly RDS wipe means anything seeded "once" is gone by the next morning's
  rebuild. `scripts/seed-historical-readings.sh` (new) backdates reading timestamps across 80
  days for demo realism, distinct from the load tests' deliberately "now"-timestamped traffic;
  a new CI step seeds a few INACTIVE/MAINTENANCE meters since `provision-meters.jmx` only ever
  creates ACTIVE ones.
- **Branch-separation integrity preserved throughout**: GitHub only discovers `schedule`/
  `workflow_dispatch` triggers from files on the default branch (`main`) — a hard platform
  constraint. Kept `aws-freetier` as the real working branch by committing every workflow change
  there first, then copying only the trigger file onto `main` via `git checkout aws-freetier --
  <file>` + a separate commit — confirmed by diff, repeatedly, that nothing else has ever landed
  on `main`. `actions/checkout`'s `ref: aws-freetier` in both workflows is what makes the actual
  executed code always come from `aws-freetier` regardless of which branch defines the trigger.
- **Real load-test instability found and worked through (Runs #8, #9, #10, each failing
  differently)** — p95/error-rate gates tuned to sit right at this architecture's ceiling turned
  out to have a ceiling that drifted across repeated same-day apply/destroy/load-test cycles
  (steady-state's own p95 crept 197ms→295ms→301ms with zero code changes; ramp-up failed once on
  a boundary-exact p95, once on a 60s error burst at peak concurrency, once on a 695ms blowout).
  Plausible cause raised and accepted: `db.t4g.micro` RDS/EC2 are burstable, CPU-credit-based,
  shared-hardware instance classes — classic noisy-neighbor/credit-exhaustion exposure, not an
  app or tuning bug.
  - Added `actions/upload-artifact` for the JTL/HTML results (`if: always()`) so a future
    failure has real response-code data instead of guessing — the results were previously only
    ever on the ephemeral runner and gone once the job ended.
  - **Re-scoped the three daily load-test steps**: they were never meant to be a genuine
    capacity test (that's `grid-meter-app-load-test.yml`'s and manual `load-tests/` runs' job) —
    here they only exist to give the demo dataset believable traffic-shape variety. Backed off
    from "tuned right at the edge" to comfortably-below-any-observed-ceiling: ramp-up to 30
    threads/30s ramp/60s duration, rapid-spike to 25 threads/20s duration (both well under
    today's failure points).
- **First-ever real run of `grid-meter-app-aws-teardown.yml`, clean, 16m38s.** Independently
  confirmed via the user's own terminal: `kubectl get nodes` fails to resolve the now-destroyed
  EKS endpoint, `terraform state list` in `terraform/aws/` is empty, and
  `terraform/aws/bootstrap-freetier/`'s state (EIP, ECR, S3 backend) is untouched, exactly as
  designed. The two "exit code" annotations on the run belong to the two
  `continue-on-error: true` informational snapshot steps that are *designed* to fail once
  resources are gone — not real failures.
- Noticed and diagnosed: tonight's first-ever scheduled teardown fire time (1:00 UTC / 6pm PDT)
  did not actually trigger (`gh run list` showed zero runs at all for that workflow before
  tonight's manual one) — most likely GitHub's documented behavior of silently skipping
  (not just delaying) scheduled triggers under platform load, not a config bug on our end
  (workflow confirmed registered and `"state": "active"`). Worth re-checking tomorrow morning
  whether the 11:00 UTC / 4am PDT startup schedule actually fires on its own.

## Current live state (as of session end)

- **Everything torn down.** `terraform/aws/` (main stack) fully destroyed, 0 resources, 0
  billing on EKS/RDS/ElastiCache/NAT/LB/NLB. `terraform/aws/bootstrap-freetier/` (persistent EIP
  `3.149.164.41` + 4 ECR repos + S3 state backend) untouched, as designed — never part of
  nightly teardown.
- `.github/workflows/grid-meter-app-aws-startup.yml` and `-teardown.yml` are byte-identical on
  `main` and `aws-freetier`, both pushed, both confirmed via `git diff`.
- Load-test parameters are now the scaled-back "demo flavor" values (not yet validated by a
  real CI run — Run #11, whenever startup next fires, is the first test of this exact config).
- `~/.kube/config`'s context points at tonight's now-destroyed cluster; irrelevant until the
  next `terraform apply` brings a new one up and CI (or a human) re-runs
  `aws eks update-kubeconfig`.

## Open / Next

1. **Awaiting the 11:00 UTC / 4am PDT scheduled startup run tomorrow morning** — first
   unattended (non-`workflow_dispatch`) firing of either schedule. Worth checking in the morning
   both that it fired at all (given tonight's teardown schedule silently didn't) and that it
   passes cleanly with today's scaled-back load-test parameters.
2. If the scheduled run doesn't fire on its own, same `gh workflow run grid-meter-app-aws-
   startup.yml --ref main` manual trigger used all day today is the fallback.
3. Once a startup run passes clean (including both daily seeding steps actually executing, not
   skipped by an earlier failure), confirm the resume-facing URL (`http://3.149.164.41/meters`)
   still comes up correctly and the demo data (status variety + historical readings) looks right.
4. Then let the stack run for a full day as originally planned, and confirm the 18:00 PDT
   teardown schedule actually fires unattended (tonight's manual run was the only one so far).
5. Still not started: frontend auto-login (agreed approach for the interview-facing fixed URL,
   scoped in conversation, zero code written yet).
