# try-flinkit — manage the local Flink cluster for the flinkit demo.
#
# These targets only drive Docker. You run flinkit itself directly — see the
# README. Point flinkit at this repo's config first (once per shell):
#
#   export FLINKIT_CONFIG=$(PWD)/flinkit.config.yaml

.PHONY: up submit down ps logs help

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

help: ## Show this help
	@grep -hE '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-8s\033[0m %s\n",$$1,$$2}'

.DEFAULT_GOAL := help
