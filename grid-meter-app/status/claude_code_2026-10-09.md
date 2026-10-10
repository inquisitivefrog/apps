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
- **A second, separate incident the same evening: an interrupted `terraform destroy` left an
  empty, still-billing EKS cluster orphaned, and the no-op check's design let it go undetected.**
  The scheduled 01:00 UTC teardown fired correctly, but the EKS node group took 8m13s to destroy
  (slower than any prior run) and the job hit its `timeout-minutes: 30` ceiling right as it reached
  `aws_eks_cluster.main: Destroying...` - GitHub Actions force-cancelled the job and orphaned the
  Terraform process mid-call.
  - Live AWS CLI inspection (after fixing an unrelated local `AWS_PROFILE` mix-up - the account
    itself was never actually inaccessible) confirmed: NAT gateway, EIP association, both Fargate
    profiles, RDS, and ElastiCache were all correctly destroyed, but the EKS cluster itself was
    still `ACTIVE` - the delete call never completed before the process was killed.
  - **Re-triggering the teardown workflow did not fix it** - its own no-op check reported
    `has_resources=false` (a false negative) and skipped the teardown job entirely. Root cause:
    the check parses one value out of `terraform output -json`
    (`eks_cluster_name`); two *other*, unrelated outputs in the same `outputs.tf`
    (`rds_endpoint`/`elasticache_endpoint`) reference the RDS/ElastiCache resources that *had*
    finished destroying, failed to evaluate, and wiped the entire outputs map as a side effect -
    including the otherwise-fine `eks_cluster_name`. The same bug shape as 2026-10-08's `-raw`
    leak (trusting `terraform output` to reflect reality), but a different, newly-discovered
    failure mode within the already-fixed `-json` approach.
  - Fixed properly from the CLI directly: found a stale state lock left by the killed process
    (`terraform force-unlock`, confirmed safe since no other process held it), ran
    `terraform plan -destroy` (clean, matched AWS reality exactly: 10 resources), then
    `terraform destroy` interactively in a real terminal (not CI, so no job timeout could kill it
    again) - completed cleanly, confirmed independently via `aws eks describe-cluster`
    (`ResourceNotFoundException`) and `aws ec2 describe-vpcs` (empty).
  - **Both workflows' no-op checks rewritten** to check actual resource presence via
    `terraform state list | grep -qx 'aws_eks_cluster.main'` instead of any `terraform output`
    value - immune to outputs being collaterally wiped by unrelated resources elsewhere in the
    same state. Also bumped the teardown job's `timeout-minutes` 30 -> 45 so a slow node-group
    destroy doesn't eat the budget needed for the cluster delete that follows it.
  - This is the third live bug found in this exact check-step pattern this week (stdout warning
    leak, then output collateral-wipe) - worth treating "no-op check reads a Terraform output" as
    inherently fragile going forward, not just this one instance.

## Current live state (as of session end)

- App fully torn down (intended nightly state) - EKS cluster, VPC, subnets, IAM roles all
  confirmed destroyed via direct `aws eks describe-cluster`/`describe-vpcs` calls, not just
  Terraform's own state. Only the persistent EIP (`3.149.164.41`, bootstrap-freetier layer,
  unassociated) remains, by design.
- AZ-pinning fix (first incident) is committed and applied live, confirmed working before the
  scheduled teardown ran.
- No-op check fix and teardown timeout bump are both committed and pushed to `aws-freetier` and
  `main`.
- EventBridge's permanent daily schedule remains `ENABLED`.

## Open / Next

1. **Watch tomorrow's unattended 11:00 UTC firing** - first real end-to-end validation with *all*
   of today's fixes live at once (AZ-pinning, hardened health-check polling, the state-list-based
   no-op check, and the 45-minute teardown timeout). Today's firing exercised AZ-pinning only;
   the no-op check and timeout fixes have not yet been validated against a real unattended
   schedule cycle, only interactively from the CLI.
2. `data.aws_availability_zones.available`'s AZ ordering (`private[0]` = `us-east-2a`) is
   empirically stable across this account's history but not a formally documented Terraform/AWS
   guarantee - worth re-confirming if this account's AZ assignment ever changes.
3. Still not started: frontend auto-login (scoped much earlier, zero code written yet).
4. Carried over from 2026-10-08: the EventBridge Connection's GitHub PAT expiration isn't tracked
   on any calendar yet. The load-test run-to-run variance's root cause also remains open (not
   blocking).
5. Consider whether any other CI check in these two workflows still leans on `terraform output`
   rather than `terraform state list` - the collateral-wipe mechanism found here (one broken
   output nulling the whole map) could affect anything else parsing output values, not just the
   no-op check.
