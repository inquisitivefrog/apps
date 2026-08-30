# PostgreSQL clustering — HA investigation

**Status: not started.** No PostgreSQL clustering/replication package
(Patroni or otherwise) has been selected yet — `docs/ha-scope.md` deferred
this scope decision behind Kafka's multi-broker pass. There's no finding to
index here yet; this file exists so the directory structure is ready the
moment a clustering package is chosen and tested.

When work starts here: record which clustering solution was selected and
why (a real scope-decision doc, same as `docs/ha-scope.md` did for Kafka),
then track runs the same way — one subdirectory per run under `runs/`,
indexed in a table here, with the real analysis living in `docs/` rather
than duplicated into this file.
