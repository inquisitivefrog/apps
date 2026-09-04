# grid-meter-app — Identity notes

Supplementary notes on identity/auth decisions not already covered in
`architecture.md`'s "Authentication" section (JWT-over-sessions, self-issued
tokens, access-token-only/no-refresh-token, in-memory client-side storage —
see that section for the full reasoning). This file collects follow-on
questions raised after that section was written, rather than expanding it
indefinitely.

## TLS / port 443

**Reversed 2026-08-27** — see `docs/cloud-deployment-scope.md`. Real
external cloud deployment (AWS/GCP/Azure) is now an explicit project
goal, which is the exact trigger this section originally named for
revisiting the no-TLS decision. Local Docker Compose / `kind` deployment
remains HTTP-only (no real network path exists there for TLS to protect).
Cloud deployments terminate TLS via cert-manager + Let's Encrypt at the
in-cluster Traefik ingress, consistent across all three providers.
