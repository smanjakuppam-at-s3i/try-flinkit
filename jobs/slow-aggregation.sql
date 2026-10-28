-- try-flinkit demo job: a high-volume keyed windowed aggregation.
--
-- `datagen` floods orders at 200k rows/sec into a 5-second tumbling
-- COUNT/SUM keyed by a high-cardinality user_id. That builds large keyed
-- RocksDB state and exercises checkpointing, and at this rate the pipeline
-- can't always keep up — so flinkit sees real throughput, checkpoint, and
-- (under load) backpressure signals to diagnose.
--
-- Tune the pressure: raise 'rows-per-second' to push harder, or lower it to
-- let the job keep up.

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

CREATE TABLE rollup (
  window_start TIMESTAMP(3),
  user_id      BIGINT,
  orders       BIGINT,
  revenue      DOUBLE
) WITH (
  'connector' = 'blackhole'
);

INSERT INTO rollup
SELECT
  window_start,
  user_id,
  COUNT(*)    AS orders,
  SUM(amount) AS revenue
FROM TABLE(
  TUMBLE(TABLE orders, DESCRIPTOR(event_time), INTERVAL '5' SECONDS)
)
GROUP BY window_start, user_id;
