# Walkthrough: diagnosing the demo job with flinkit

A narrated tour of the demo. It assumes you've installed flinkit and have
Docker running. `make` manages the local Flink cluster; everything else is
flinkit run directly.

First, point flinkit at this repo's config so it finds the local cluster (once
per shell):

```sh
export FLINKIT_CONFIG=$PWD/flinkit.config.yaml
```

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
submits the streaming `INSERT` to the session cluster, prints a job id, and
exits. The job keeps running on the cluster.

The job runs a 5-second tumbling `COUNT`/`SUM` keyed by a 500k-cardinality
`user_id` at 200k rows/sec on a **deliberately small TaskManager**. That builds
far more RocksDB state than it can checkpoint in time — so this isn't a
throughput problem, it's an **under-provisioned job that fails its checkpoints
and restart-loops.** A very common, very real production failure — and exactly
what flinkit is built to explain.

## 3. Find the job

```sh
flinkit scan
```

`scan` lists the running jobs with their ids and state. You'll see
`orders-rollup`. The commands below take either the job **id** or its **name**,
so you can just use `orders-rollup`.

## 4. Live triage — `inspect`

```sh
flinkit inspect orders-rollup --watch
```

This is the main event. The dashboard refreshes live; watch for:

- **checkpoints** — a climbing failure count (e.g. `4✓ 39✗`) with a huge average
  duration (tens of seconds), and a `cp N failed … Asynchronous task checkpoint
  failed` line with the correlated log underneath.
- **restarts** — ticking up (the job can't complete a checkpoint, so it keeps
  failing over), with a `last failure … FlinkRuntimeException` line.
- **findings** — `HIGH DOC-CKPT-001` (checkpoints failing) and
  `MEDIUM DOC-STAB-001` (repeated restarts) called out inline.
- **bottleneck: none** — a teaching point: the job *isn't* backpressured, so
  there's no choke point. Its problem is checkpointing/stability, not throughput
  — and flinkit says so rather than inventing a bottleneck.

Press `c` to expand the **config** panel (parallelism, checkpoint interval,
state backend, TM memory — note the small heap/managed memory driving the
failures). Press `l` to fold/unfold logs, `w` to filter to warnings, `q` to quit.

> **Screenshot:** `screenshots/inspect.png`

## 5. One-shot verdict — `doctor`

```sh
flinkit doctor
```

`doctor` runs the health checks and ranks the findings:

- **`HIGH DOC-CKPT-001`** — *Checkpoints are failing; the job cannot recover
  cleanly from failure.* Select it for the detail: the target job id, the
  evidence (`N checkpoint(s) have failed`), a fix, and a docs link.
- **`MEDIUM DOC-STAB-001`** — *The job has restarted; repeated restarts point to
  an unstable pipeline.*

> **Screenshot:** `screenshots/doctor.png`

## 6. Experiment — make the diagnosis change

- **Fix it:** give the TaskManager more memory (raise `taskmanager.memory.*` /
  the managed-memory fraction in `docker-compose.yml`) and/or lower
  `rows-per-second` in the SQL, then `make down && make up && make submit`.
  Watch the checkpoints start succeeding and `DOC-CKPT-001` / `DOC-STAB-001`
  clear.
- **Make it worse:** raise `rows-per-second` and resubmit — checkpoints fail
  faster and restarts climb quicker.

## 7. Tear down

```sh
make down
# docker compose down -v
```
