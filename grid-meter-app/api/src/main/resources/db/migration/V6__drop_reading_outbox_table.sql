-- Reverts V5. The reading_outbox table (Stage A of a transactional-outbox pattern for
-- Kafka-publish failures) was built and load-tested (load-tests/kafka-ha-demo.sh,
-- since-removed outbox-growth-stageB.sh), then retired: a table with no reconciler to drain
-- it isn't durability, and this project's redo-path analysis concluded a lost simulated
-- meter reading has no real consequence worth building that durability for. See
-- docs/resilience-scope.md for the full reasoning. A new migration drops it rather than
-- editing/deleting V5, since V5 is already applied (and recorded in flyway_schema_history)
-- against any environment that ran this app before this change.
DROP TABLE reading_outbox;
