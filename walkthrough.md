# Walkthrough: diagnosing the demo job with flinkit

A narrated tour of the demo. It assumes you've installed flinkit and have
Docker running. Every command is also a `make` target — both forms are shown.

## 1. Start the cluster

```sh
make up
# docker compose up -d jobmanager taskmanager
```

Wait a few seconds, then open the Flink web UI at <http://localhost:8081> to
confirm one TaskManager with two free slots is registered.

## 2. Submit the job

```sh
make submit
# docker compose run --rm sql-client
```

The SQL client runs [`jobs/slow-aggregation.sql`](jobs/slow-aggregation.sql),
submits the streaming `INSERT` to the session cluster, prints a **job id**, and
exits. The job keeps running on the cluster.

The job floods a 5-second tumbling `COUNT`/`SUM` keyed by a 500k-cardinality
`user_id` at 200k rows/sec — enough to build real keyed state and, often, to
backpressure the pipeline.

## 3. Find the job

```sh
make scan
# flinkit scan
```

`scan` lists the running jobs with their ids and state. Copy the id of
`orders-rollup` for the next steps.

## 4. Live triage — `inspect`

```sh
make inspect JOB=<job-id>
# flinkit inspect <job-id> --watch
```

This is the main event. The dashboard refreshes live; watch for:

- **operators** — the keyed aggregation climbing toward 100% *busy*, and the
  source showing *backpressure* when the aggregation can't keep up.
- **checkpoints** — duration and state size growing as keyed state accumulates
  (RocksDB backend).
- **i/o** — throughput (records/sec) once two snapshots are in.
- **bottleneck** — the constrained operator called out at the bottom.

Press `c` to expand the **config** panel (parallelism, checkpoint interval,
state backend, TM memory). Press `l` to fold/unfold logs, `w` to filter to
warnings, `q` to quit.

> **Screenshot:** `screenshots/inspect.png`

## 5. One-shot verdicts — `bottleneck` and `doctor`

```sh
make bottleneck JOB=<job-id>
# flinkit bottleneck <job-id>
```

`bottleneck` names the constrained operator and classifies the cause — here,
key-skew / a heavy keyed aggregation rather than a slow external sink.

> **Screenshot:** `screenshots/bottleneck.png`

```sh
make doctor
# flinkit doctor
```

`doctor` runs health and configuration checks. On this cluster it flags
**`DOC-CFG-003`** — RocksDB incremental checkpoints are disabled, so every
checkpoint re-uploads full state. (The demo sets `state.backend.incremental:
false` on purpose so you can see a config finding.) Depending on load you may
also see checkpoint or backpressure findings.

> **Screenshot:** `screenshots/doctor.png`

## 6. Experiment

- Raise `rows-per-second` in the SQL file and re-submit to push harder; lower it
  to let the job catch up and watch backpressure disappear.
- Flip `state.backend.incremental` to `true` in `docker-compose.yml`, restart
  (`make down && make up && make submit`), and confirm `DOC-CFG-003` clears.

## 7. Tear down

```sh
make down
# docker compose down -v
```
