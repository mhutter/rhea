SECRETS = $(wildcard apps/*/*.secret.yaml)
SEALED_SECRETS = $(patsubst %.secret.yaml, %.sealed-secret.json, $(SECRETS))

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_.%-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

secrets: $(SEALED_SECRETS) ## (re)generate all SealedSecrets

%.sealed-secret.json: %.secret.yaml ## Generate SealedSecret from a Secret
	kubeseal -f $< > $@
