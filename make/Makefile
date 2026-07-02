# ==============================================================================
# Development Automation Tooling Matrix
# ==============================================================================

.PHONY: help init-dev install-linter lint fmt-check fmt-fix dev-sync pre-commit

CONFIG_PATH := .dev/linters/golinter.yaml
LINTER_VERSION := v2.12.2
PUSH ?= false
SYNC ?= false
TIDY ?= false

help: ## Display available technical execution targets
	@echo "================================================================================"
	@echo "Available Development Automation Targets (Alphabetical):"
	@echo "================================================================================"
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' | sort
	@echo "================================================================================"

init-dev: ## Initialize whole local workspace architecture (submodules sync, hooks mapping, and platform fixes)
	@echo "================================================================================"
	@echo "[RUN] Initializing and pulling global governance submodules recursively..."
	@echo "================================================================================"
	git submodule update --init --recursive
	@echo "[ . ] Configuring structural Git lifecycle hooks mapping..."
	git config core.hooksPath .dev/hooks
	@echo "[ . ] Enforcing canonical LF line endings globally for this repository context..."
	git config core.autocrlf false
	@echo "[OKK] Development workspace architecture initialized successfully."

install-linter: ## Fetch and provision the official golangci-lint binary if version criteria is unmet
	@echo "================================================================================"
	@echo "[RUN] Verifying local static analysis engine requirements..."
	@echo "================================================================================"
	@if command -v golangci-lint &> /dev/null; then \
		CURRENT_VER=$$($$(command -v golangci-lint) --version | awk '{print $$4}'); \
		echo "  [ . ] Current local version found: v$$CURRENT_VER"; \
		if [ "$$(printf '%s\n%s' "2.12.2" "$$CURRENT_VER" | sort -V | head -n1)" != "2.12.2" ]; then \
			echo "  [ x ] Installed version v$$CURRENT_VER is lower than required v2.12.2. Upgrading..."; \
			curl -sSfL https://golangci-lint.run | sh -s -- -b $$(go env GOPATH)/bin $(LINTER_VERSION); \
		else \
			echo "  [ v ] Local version satisfies the minimum requirements (>= v2.12.2)."; \
		fi \
	else \
		echo "  [ . ] golangci-lint engine missing. Fetching official binary $(LINTER_VERSION)..."; \
		curl -sSfL https://golangci-lint.run | sh -s -- -b $$(go env GOPATH)/bin $(LINTER_VERSION); \
	fi
	@echo "[ . ] Installing gofumpt vertical layout engine..."
	@go install mvdan.cc/gofumpt@latest
	@echo "[OKK] Local environment binaries provisioned successfully."

lint: ## Execute comprehensive semantic static analysis checks recursively across the workspace
	@echo "================================================================================"
	@echo "[RUN] Initializing deep analytical validation checks..."
	@echo "================================================================================"
	golangci-lint run --config="$(CONFIG_PATH)" ./...
	@echo "[OKK] Static analysis complete with zero errors."

fmt-check: ## Execute a recursive read-only audit to detect layout anomalies against gofumpt rules
	@echo "================================================================================"
	@echo "[RUN] Executing dry-run structural layout verification..."
	@echo "================================================================================"
	gofumpt -d .

fmt-fix: ## Force rewrite of all Go modules to comply with strict structural formatting definitions
	@echo "================================================================================"
	@echo "[RUN] Overwriting structural modules to enforce canonical layouts..."
	@echo "================================================================================"
	gofumpt -w .
	@echo "[OKK] Source files successfully normalized."

.dev-sync:
	@echo "[ . ] Synchronizing centralized .dev governance submodule..."
	@cd .dev && git fetch origin --prune --quiet && git reset --hard origin/main --quiet
	@echo "[OKK] Centralized submodule successfully aligned with origin/main."

dev-sync: .dev-sync ## Manually force sync local .dev directory with upstream remote main branch

amend: ## Stage all mutations, apply optional upstream sync, and execute git amend [SYNC=true] [PUSH=true] [TIDY=true]
	@if [ "$(SYNC)" = "true" ]; then \
		$(MAKE) .dev-sync || exit 1; \
	fi
	@if [ "$(TIDY)" = "true" ]; then \
		echo "[ . ] Executing analytical Go toolchain dependency pruning (go mod tidy)..."; \
		go mod tidy || { echo "[ x ] Error: go mod tidy processing collapsed."; exit 1; }; \
	fi
	@echo "[ . ] Staging all workspace mutations..."
	git add .
	@echo "[ . ] Executing git commit amend process..."
	@# Sequential Gate: Enforce strict execution continuity chain via standard bash operators
	git commit --amend --no-edit && \
	if [ "$(PUSH)" = "true" ]; then \
		echo "[ . ] Executing forced upstream synchronization push..."; \
		git push -f && \
		echo "[ v ] Upstream force push complete."; \
	fi && \
	echo "[OKK] Amend sequence executed successfully."


amend-s-p: ## Direct alias shortcut to execute the complete sync, amend, and force push sequence
	@$(MAKE) amend SYNC=true PUSH=true

create-pkg: ## Inject a blueprint package into workspace [TMPL=name] [SCOPE=internal|pkg] [PREFIX=name] [BASE=path]
	@echo "================================================================================"
	@echo "[RUN] Initializing architectural package injection process..."
	@echo "================================================================================"
	@if [ -z "$(TMPL)" ] || [ -z "$(SCOPE)" ] || [ -z "$(PREFIX)" ]; then \
		echo "[ x ] Missing required orchestration variables."; \
		echo "  Usage: make create-pkg TMPL=<name> SCOPE=<internal|pkg> PREFIX=<name> [BASE=<path>]"; \
		echo ""; \
		./.dev/scripts/createpkg.sh help; \
		exit 1; \
	fi
	./.dev/scripts/createpkg.sh $(TMPL) $(SCOPE) $(PREFIX) $(BASE)

pre-commit: ## Safe automation gateway pipeline to stage, optimize and commit code [MSG="text"] [TIDY=true]
	@echo "================================================================================"
	@echo "[RUN] Initializing local pre-commit automation pipeline..."
	@echo "================================================================================"
	@if [ -z "$(MSG)" ]; then \
		echo "[ x ] Validation Failure: Target commit message cannot be empty."; \
		echo "  Usage: make pre-commit MSG=\"your commit message description here\" [TIDY=true]"; \
		echo "[ERR] Automation pipeline execution aborted."; \
		exit 1; \
	fi
	@if [ "$(TIDY)" = "true" ]; then \
		echo "[ . ] Executing analytical Go toolchain dependency pruning (go mod tidy)..."; \
		go mod tidy || { echo "[ x ] Error: go mod tidy processing collapsed."; exit 1; }; \
	fi
	@echo "[ . ] Staging all local workspace mutations safely..."
	git add .
	@echo "[ . ] Handing over control to local Git lifestyle hooks matrix..."
	@# The double-ampersand chain completely blocks the workflow sequence if the commit hooks reject the code
	git commit -m "$(MSG)" && \
	echo "[OKK] Master pre-commit automation sequence executed perfectly!"
