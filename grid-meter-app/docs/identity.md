# grid-meter-app — Identity notes

Supplementary notes on identity/auth decisions not already covered in
`architecture.md`'s "Authentication" section (JWT-over-sessions, self-issued
tokens, access-token-only/no-refresh-token, in-memory client-side storage —
see that section for the full reasoning). This file collects follow-on
questions raised after that section was written, rather than expanding it
indefinitely.

## TLS / port 443: not needed for this project

**Decision: no HTTPS entrypoint, now or planned.** Traefik's single
entrypoint is `:80` in both Docker Compose and `k8s/traefik.yaml`
(`--entrypoints.web.address=:80`) — no `:443`/TLS entrypoint is defined
anywhere in the stack.

**Reasoning:**

- The JWT auth design is already stateless-bearer-header, chosen
  specifically to avoid cookie/CSRF machinery (see `architecture.md`). TLS
  isn't required for that mechanism to function.
- Everything in this project's actual deployment surface is local —
  Docker Compose on the dev machine, `kind` for the k8s demo — so there's
  no real network path for TLS to protect against (the threat it defends
  against is token interception in transit across an untrusted network,
  which doesn't apply to localhost/local-cluster traffic). Same reasoning
  already applied to ruling Terraform out of scope: no real external
  target exists here to justify the infrastructure.
- Adding TLS termination at Traefik was considered as part of the
  httpOnly-cookie approach when the auth model was first decided, and
  rejected there for the same reason: it would pull in SameSite/CSRF
  machinery that undoes the simpler stateless-bearer-header design.

**Revisit only if** this project's scope ever grows to include a real
externally-reachable deployment (same trigger condition already documented
for reconsidering Terraform in `architecture.md`'s "Terraform — explicitly
out of scope" section). Until then, port 443 stays unused by design, not by
oversight.
