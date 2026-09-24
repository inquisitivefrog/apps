# grid-meter-app — Status: 2026-09-24 (Claude Code)

Closed out the multi-cloud Lettuce Redis credential-provider effort that spanned yesterday and
today: AWS (started yesterday, finished and live-verified today), then GCP, then Azure, each one
scoped and implemented individually, live-verified against real infrastructure, committed, and
torn down before moving to the next — per the user's own explicit sequencing ("commit and push,
then move forward with code changes, then retest one platform at a time"). All three clouds now
have real, working IAM/token-based Redis auth (`5480d06` AWS, `f79e276` GCP, `e6465b8` Azure), and
all three environments are currently fully torn down.

## Done — AWS: credential-provider live-verified, observability/Traefik teardown gap fixed, fully torn down

Picked up from last night's #1 open item: confirm the AWS Lettuce credential-provider code
(implemented but never exercised against a live pod) actually works. It did — a real
`Redis write attempt SUCCEEDED` log line confirmed via `kubectl logs` against a live pod and real
ElastiCache, not just passing unit tests. Found and fixed one real bug on the way:
`software.amazon.awssdk:sts` was missing from `pom.xml`, silently breaking
`WebIdentityTokenFileCredentialsProvider` (the actual IRSA mechanism) behind a generic
`RedisConnectionFailureException` whose real cause was one `Caused by:` clause deeper.

**Separately found and fixed a real regression**: `k8s/deploy-observability.sh`'s "re-apply
`traefik.yaml`" step was stale residue from before the multi-cloud `traefik-{aws,gcp,azure}.yaml`
split — it silently overwrote a live AWS deployment's correct Traefik Deployment with the
`kind`-only manifest (`nodeSelector: ingress-ready=true`, meaningless on real cloud nodes),
breaking ingress. Removed the stale step, repaired the live Deployment, and added an
observability-aware "Observability" section to all three `check-resources-*.sh` scripts plus a
new Step 4 (`helm uninstall` + delete Loki/Tempo/Alloy/ServiceMonitor) to all three
`teardown-*.sh` scripts — live-tested clean on AWS with the stack genuinely deployed.

Full cycle re-verified end to end: `terraform apply` (51 resources) → `deploy-aws.sh` →
`deploy-observability.sh` → live Redis-auth confirmation → `teardown-aws.sh` (including the new
Step 4) → `terraform destroy` (51 resources) → 9 independent AWS API residue checks, all empty.
Committed as `5480d06`.

## Done — GCP: credential-provider implemented and live-verified, several real bugs found along the way

New `config.gcp` package mirroring AWS's structure: username the literal `"default"`, password a
GCP OAuth2 access token from `IamCredentialsClient.generateAccessToken()` **self-impersonating**
the app's own service account (matching Google's own official Lettuce IAM-auth reference sample,
not guessed) — required a new `roles/iam.serviceAccountTokenCreator`-on-itself Terraform grant
beyond the existing Workload Identity binding.

Real bugs found and fixed:
- **`com.google.cloud:libraries-bom` pinned `protobuf-java` below what OpenTelemetry's own
  generated proto classes needed**, breaking the *entire* Spring context (not just GCP beans) at
  OTLP-exporter init time — fixed by explicitly pinning `protobuf-java` to override the BOM.
- **A live `SSLHandshakeException` ("PKIX path building failed")** connecting to Memorystore —
  its TLS cert uses a private, per-instance Google-managed CA; `useSsl()` alone only sets a simple
  on/off flag, not a trust manager. Fixed via a dedicated
  `LettuceClientOptionsBuilderCustomizer` bean wiring a custom trust manager built from a new
  Terraform output (a joined PEM bundle from `google_memorystore_instance`'s nested
  `managed_server_ca` attribute), mounted into the pod via a ConfigMap.
- **A self-caused live outage**: applied `api-gcp.yaml` directly via `kubectl apply -f` without
  running it through `deploy-gcp.sh`'s `sed` placeholder substitution, applying literal
  `PLACEHOLDER_*` strings as real values — combined with a rollout-strategy change already in
  flight, this took `api` fully offline. Owned immediately, fixed by re-running with real values
  substituted via `terraform output -raw`.
- **A live node-pool memory capacity ceiling** (`0/4 nodes are available: 4 Insufficient memory`)
  — this pool (4× e2-medium) was already at 97-98% memory requests running the app plus the full
  observability slice, with no headroom for `RollingUpdate`'s surge pod. Fixed by switching `api`'s
  rollout strategy to `Recreate` (accepted brief-downtime tradeoff for a demo project).
- **`check-resources-gcp.sh`'s GCE-worker-instance check never actually validated a count**
  despite its own label claiming "(expect 3, RUNNING)" — its `check()` function had no
  expected-value parameter at all, unlike AWS's/Azure's identical scripts. Replaced with a real
  count comparison (now correctly expecting 4: the main pool's 3 nodes + the extra pool's 1).
- **A `GCE_STOCKOUT` spanning two of three node-pool zones simultaneously** — resolved by dropping
  `gke_node_locations` to `us-central1-a` only and raising `gke_node_count` to 3 to preserve the
  original 3-node-total intent.

Full suite re-run clean after every dependency change (102/102, zero regressions). Live-verified
two ways: a real `Redis write attempt SUCCEEDED` log line from a running pod, and a manual
`kubectl exec` walkthrough (with the user) doing the token-and-connect flow by hand — including a
real grep mistake mid-walkthrough (fixed live) before it succeeded cleanly. Committed as
`f79e276`, then fully torn down (`terraform destroy`: 25 resources, zero errors; independently
confirmed against 9 real GCP API residue checks, all empty).

## Done — Azure: credential-provider implemented and live-verified two independent ways

Researched the real mechanism rather than assuming AWS's/GCP's patterns transferred: **Lettuce
itself already ships `io.lettuce.authx.TokenBasedRedisCredentialsProvider`** (confirmed via
`javap` against the installed jar), paired with `redis.clients.authentication:redis-authx-entraid`
(version `0.1.1-beta2`, confirmed via Maven Central, not a guessed number). The doc page's
`.userAssignedManagedIdentity(...)` path is narrower/IMDS-oriented; the correct general path
(`AzureTokenAuthConfigBuilder.defaultAzureCredential(DefaultAzureCredential)`) was found by reading
the library's real GitHub source, not the docs alone. A genuine structural difference from
AWS/GCP: `DefaultAzureCredential`'s own `WorkloadIdentityCredential` fallback reads
AKS-webhook-injected env vars automatically, so **no app-level identity value needs to be threaded
through as an explicit env var at all** for Azure.

Found live that AKS Workload Identity needs **two** things together, not one: the
`azure.workload.identity/client-id` annotation on the ServiceAccount, *and* the
`azure.workload.identity/use: "true"` label on the pod template itself — without the pod label,
the webhook never mutates the pod at all.

**A real infinite-retry bug, initially misread as a hang**: a `mvn test` run for the new Azure
code appeared stuck (8+ minutes, near-zero CPU). Killed it; the user then gave an explicit
**"stop"** mid-diagnosis, honored immediately with no further action until re-engaged. On resuming,
root-caused properly via a thread dump rather than guessing again:
`redis-authx-entraid`'s `AzureIdentityProvider` parses the access token as a real JWT and reads
two claims — `oid` (the Redis AUTH *username*, dynamically, not a fixed string) and `exp` — and a
test's plain non-JWT fake string caused every renewal attempt to fail identically and retry
forever, invisible to a `.block()` caller. Fixed by constructing a structurally-valid fake JWT in
the test. Full suite confirmed clean afterward: 103/103.

Terraform applied live (20 resources) — after the user's own correction that my initial "no
preliminaries needed" answer wasn't actually verified (a clean `terraform plan` doesn't prove
resource-provider registration, which historically only surfaced at `apply` time for this exact
project); live-checked all 11 required Azure provider registrations via `az provider show` before
proceeding. `k8s/deploy-azure.sh` and `deploy-observability.sh` both ran clean
(`check-resources-azure.sh`: 21/21, including the observability stack).

**Live-verified two independent ways**, matching AWS's/GCP's bar:
1. App logs: a real `Redis write attempt SUCCEEDED` line from a live pod (the very first test
   reading's log took longer than expected to appear — traced to cold-start latency on the first
   ever Entra ID token exchange/TLS handshake, not a bug; a second reading logged cleanly in
   338ms).
2. A manual `kubectl exec` walkthrough doing the Entra ID token exchange by hand from inside a
   running pod (same federated-token-file mechanism `DefaultAzureCredential` uses internally):
   exchanged the projected workload-identity token for a real access token, decoded its `oid`
   claim, connected to Managed Redis over TLS with `redis-cli`, got `PONG`, and read back the exact
   JSON the app had written earlier — proving the write landed for real, not just that a log line
   printed.

Torn down clean (`teardown-azure.sh` ran clean on its first-ever real run; `terraform destroy`: 20
resources, zero errors; 8/8 independent Azure API residue checks empty, including both the main
and AKS-auto-created node resource groups).

**One real secret-hygiene catch before committing**: a raw status-log transcript
(`status/redis_azure_test_2026-09-24.md`) had captured the actual Entra ID access token in full
from the manual walkthrough. Scanned all new/modified status files for secret patterns before
staging, found and redacted it (the token was already moot — its Redis instance and identity had
just been destroyed — but real credential material still shouldn't go into git history). Committed
as `e6465b8`.

## Open

- **All three clouds are fully torn down** as of tonight — zero resources, independently confirmed
  against real cloud APIs for each, no cost currently accruing. Next session's first real step for
  any demo would be a fresh `terraform apply` + `deploy-*.sh`.
- **Longer-carried items, untouched today**: `kafka-leader-failover-rto.sh`'s JVM-spawn-cost fix,
  `docs/testing-expansion-scope.md` task #9+.

## Next

1. No outstanding credential-provider work remains on any cloud — this effort is closed. Future
   multi-cloud sessions can start from a clean baseline (redeploy → verify → demo → teardown)
   rather than scoping new auth work.
2. Pick up the longer-carried backlog items above whenever multi-cloud work isn't the active
   focus.
