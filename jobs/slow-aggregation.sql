-- try-flinkit demo job: a high-volume keyed windowed aggregation.
--
-- `datagen` floods orders at 200k rows/sec into a 5-second tumbling
-- COUNT/SUM keyed by a high-cardinality user_id. That builds more keyed RocksDB
-- state than the (deliberately small) TaskManager can checkpoint in time, so
-- checkpoints fail and the job restart-loops — the realistic under-provisioned
-- failure flinkit diagnoses (DOC-CKPT-001 / DOC-STAB-001).
--
-- Tune it: lower 'rows-per-second' (and/or give the TM more memory in
-- docker-compose.yml) to let checkpoints succeed; raise it to fail faster.

SET 'pipeline.name' = 'orders-rollup';

CREATE TABLE orders (
  user_id    BIGINT,
  amount     DOUBLE,
  event_time AS PROCTIME()
) WITH (
  'connector'          = 'datagen',
  'rows-per-second'    = '200000',
  'fields.user_id.min' = '1',
  'fields.user_id.max' = '500000',
  'fields.amount.min'  = '1',
  'fields.amount.max'  = '1000'
);

CREATE TABLE orders_rollup (
  window_start TIMESTAMP(3),
  user_id      BIGINT,
  orders       BIGINT,
  revenue      DOUBLE
) WITH (
  'connector' = 'blackhole'
);

INSERT INTO orders_rollup
SELECT
  window_start,
  user_id,
  COUNT(*)    AS orders,
  SUM(amount) AS revenue
FROM TABLE(
  TUMBLE(TABLE orders, DESCRIPTOR(event_time), INTERVAL '5' SECONDS)
)
GROUP BY window_start, user_id;
