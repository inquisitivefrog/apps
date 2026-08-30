# Redis / Sentinel — HA investigation

**Status: not started.** `docs/ha-scope.md` deferred Redis HA testing behind
Kafka's multi-broker pass being built, tested, and closed out. No Sentinel
cluster has been stood up against this project yet, so there's no finding to
index here — this file exists so the directory structure is ready the moment
that work starts, per the same layout `../kafka/NOTES.md` uses once it has
real runs to index.

When work starts here: scope the actual HA topology first (a real
scope-decision doc, same as `docs/ha-scope.md` did for Kafka), then track
runs the same way — one subdirectory per run under `runs/`, indexed in a
table here, with the real analysis living in `docs/` rather than duplicated
into this file.
