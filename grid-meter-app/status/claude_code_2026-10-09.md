# 2026-10-09 — A real production outage, root-caused and fixed live; data re-seeded

## Done

- **Diagnosed and fixed a real, previously-undiscovered outage**: EventBridge's first unattended
  11:00 UTC firing deployed cleanly (every pod `Ready`, all CI checks green), but the app was
  100% unreachable for over 5 hours before caught manually - a TCP SYN timeout (confirmed via
  `curl`/`nc`/`ping` all independently failing, not an HTTP-level error).
  - Ruled out, in order, via live AWS CLI diagnosis (not guessed): the EIP itself (still correctly
    associated), DNS, security groups, NACLs. Root cause found via
    `aws elb describe-target-health` on the NLB: the traefik target showed
    `State: "unused"` / `Reason: "Target.NotInUse"` / `"Target is in an Availability Zone that is
    not enabled for the load balancer"`.
  - Mechanism: the NLB is pinned to a single AZ (`us-east-2a`, matching the single persistent EIP
    in `eip.tf`), but the existing Fargate profile spans all 3 private subnets with no AZ
    awareness - Fargate happened to schedule the traefik pod into `us-east-2b` this run. Every
    `kubectl`-level health check passed cleanly throughout; nothing in the deploy pipeline itself
    was wrong.
  - Fixed with a new, dedicated `aws_eks_fargate_profile.traefik_single_az` in
    `terraform/aws/fargate.tf`, scoped to one subnet (`us-east-2a`) and a distinct pod label
    (`fargate-single-az: "true"`, not the shared `fargate: "true"` api/frontend use - avoids AWS's
    documented undefined behavior when a pod could match more than one profile's selector).
    `k8s/traefik-aws.yaml` updated to the new label. Plan: `1 to add, 0 to change, 0 to destroy`;
    applied live by the user, verified working (NLB target `healthy`, live HTTP 200).
  - Required adding one new read-only IAM permission mid-diagnosis
    (`elasticloadbalancing:Describe*`) to the human's `grid-meter-app-terraform` policy - a
    diagnostic gap, not the cause of the outage itself; clarified this distinction directly after
    an initial unclear explanation.
  - Confirmed with the user this is a point fix scoped to this specific AZ-pinning setup (NLB +
    single EIP + Fargate), not a general guarantee against all future scheduling-related
    surprises - acceptable given this is a demo, not a production service with an uptime SLA.
- **Re-seeded demo data** after the outage left the app online but empty (the automated pipeline's
  seeding steps never ran - it never got past the login health check that morning). Replayed the
  pipeline's own steps manually, in the correct order (steady-state load test creates meters first;
  historical-reading seeding requires meters to already exist):
  1. `steady-state` load test - 18,256 samples, 0% error rate, p95 245.0ms, all gates passed.
  2. Meter status variety seeding (INACTIVE/MAINTENANCE) - 6 meters created, 0 errors.
  3. `scripts/seed-historical-readings.sh` - 780 readings posted across 26 meters, 0 failures.
  - Final state verified directly against the live API: **26 meters** (20 ACTIVE, 3 MAINTENANCE,
    3 INACTIVE), **19,929 total readings**. Zero errors across all three steps, so the
    conditionally-authorized "fix scripts and re-seed on error" branch was never triggered.
- **Hardened the "End-to-end login health check" step** in
  `grid-meter-app-aws-startup.yml` from a single, no-retry `curl` attempt (the exact gap that let
  today's outage run for 5+ hours before detection) to a 12-attempt, 10-second-interval poll (up to
  2 minutes), logging each attempt's HTTP status and failing loud with the last response body if
  every attempt fails.

## Current live state (as of session end)

- App live and fully seeded at `http://3.149.164.41` - online, reachable, 26 meters / 19,929
  readings, traefik correctly pinned to the NLB's enabled AZ.
- AZ-pinning fix is committed and already applied live (not just planned).
- EventBridge's permanent daily schedule remains `ENABLED` - today's 11:00 UTC firing is the one
  that surfaced this outage; tomorrow's firing is the first real unattended test *with* the fix in
  place.

## Open / Next

1. **Watch tomorrow's unattended 11:00 UTC firing** - first clean end-to-end validation of the
   permanent schedule with the AZ-pinning fix live (today's firing deployed successfully but was
   unreachable; the fix went in and was verified manually afterward, not via a second automated
   cycle yet).
2. `data.aws_availability_zones.available`'s AZ ordering (`private[0]` = `us-east-2a`) is
   empirically stable across this account's history but not a formally documented Terraform/AWS
   guarantee - worth re-confirming if this account's AZ assignment ever changes.
3. Still not started: frontend auto-login (scoped much earlier, zero code written yet).
4. Carried over from 2026-10-08: the EventBridge Connection's GitHub PAT expiration isn't tracked
   on any calendar yet. The load-test run-to-run variance's root cause also remains open (not
   blocking).
