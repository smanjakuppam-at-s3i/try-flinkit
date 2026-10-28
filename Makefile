# try-flinkit — watch flinkit diagnose a live, local Flink job.
#
# Point flinkit at the repo-local config so the demo never touches ~/.flinkit.
export FLINKIT_CONFIG := $(CURDIR)/flinkit.config.yaml

# Job id for inspect/bottleneck:  make inspect JOB=<id>
JOB ?=

.PHONY: up submit down ps logs scan doctor inspect bottleneck help

up: ## Start the Flink cluster (web UI http://localhost:8081)
	docker compose up -d jobmanager taskmanager

submit: ## Submit the example SQL job to the cluster
	docker compose run --rm sql-client

down: ## Stop the cluster and wipe its state
	docker compose down -v

ps: ## Show cluster status
	docker compose ps

logs: ## Tail the cluster logs
	docker compose logs -f jobmanager taskmanager

scan: ## List the jobs flinkit can see
	flinkit scan

doctor: ## Run flinkit's health + config checks
	flinkit doctor

inspect: ## Live triage of a job:  make inspect JOB=<job-id>
	flinkit inspect $(JOB) --watch

bottleneck: ## Bottleneck analysis of a job:  make bottleneck JOB=<job-id>
	flinkit bottleneck $(JOB)

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-11s\033[0m %s\n",$$1,$$2}'

.DEFAULT_GOAL := help
