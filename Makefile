.PHONY: help fmt validate lint security plan-dev apply-dev destroy-dev plan-prod apply-prod destroy-prod init check

# Default target
.DEFAULT_GOAL := help

TERRAFORM := terraform
TFLINT := tflint
TFSEC := tfsec

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Display this help message
	@echo "$(BLUE)Terraform AWS Landing Zone - Make Targets$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make validate        # Run format, validate, lint"
	@echo "  make plan-dev        # Plan both stacks for dev"
	@echo "  make apply-dev       # Apply both stacks for dev"
	@echo "  make destroy-dev     # Destroy both stacks for dev"

# ============================================================================
# Quality Checks
# ============================================================================

validate: fmt-check validate-tf lint ## Run format check, validate, and lint

fmt: ## Auto-format all Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) fmt -recursive .
	cd stacks/network && $(TERRAFORM) fmt -recursive .
	@echo "$(GREEN)✓ Formatting complete$(NC)"

fmt-check: ## Check if Terraform files are formatted correctly
	@echo "$(BLUE)Checking Terraform formatting...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) fmt -check -recursive .
	cd stacks/network && $(TERRAFORM) fmt -check -recursive .
	@echo "$(GREEN)✓ Format check passed$(NC)"

validate-tf: ## Validate Terraform syntax
	@echo "$(BLUE)Validating Terraform...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) validate
	cd stacks/network && $(TERRAFORM) validate
	@echo "$(GREEN)✓ Validation passed$(NC)"

lint: ## Run tflint (if installed)
	@echo "$(BLUE)Running tflint...$(NC)"
	@command -v $(TFLINT) >/dev/null 2>&1 || { echo "$(YELLOW)⚠ tflint not installed$(NC)"; exit 0; }
	cd stacks/bootstrap && $(TFLINT) --init > /dev/null && $(TFLINT) .
	cd stacks/network && $(TFLINT) --init > /dev/null && $(TFLINT) .
	@echo "$(GREEN)✓ Lint check passed$(NC)"

security: ## Run tfsec security scan
	@echo "$(BLUE)Running tfsec security scan...$(NC)"
	@command -v $(TFSEC) >/dev/null 2>&1 || { echo "$(YELLOW)⚠ tfsec not installed$(NC)"; exit 0; }
	$(TFSEC) . -f json
	@echo "$(GREEN)✓ Security scan complete$(NC)"

check: ## Run all quality checks (alias for validate)
	$(MAKE) validate

# ============================================================================
# Development Environment
# ============================================================================

init-dev: ## Initialize Terraform for dev environment
	@echo "$(BLUE)Initializing dev environment...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) init
	@echo "$(GREEN)✓ Bootstrap initialized$(NC)"
	cd stacks/network && $(TERRAFORM) init -backend-config=../../envs/dev/network.backend.hcl
	@echo "$(GREEN)✓ Network initialized$(NC)"

plan-dev: ## Plan both bootstrap and network for dev
	@echo "$(BLUE)Planning bootstrap (dev)...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) plan -var-file=../../envs/dev/bootstrap.tfvars -out=bootstrap.tfplan
	@echo ""
	@echo "$(BLUE)Planning network (dev)...$(NC)"
	cd stacks/network && $(TERRAFORM) plan -var-file=../../envs/dev/network.tfvars -out=network.tfplan
	@echo ""
	@echo "$(GREEN)✓ Plans created (bootstrap.tfplan, network.tfplan)$(NC)"

apply-dev-bootstrap: ## Apply bootstrap stack for dev
	@echo "$(BLUE)Applying bootstrap (dev)...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) apply -var-file=../../envs/dev/bootstrap.tfvars

apply-dev-network: ## Apply network stack for dev
	@echo "$(BLUE)Applying network (dev)...$(NC)"
	cd stacks/network && $(TERRAFORM) apply -var-file=../../envs/dev/network.tfvars

apply-dev: apply-dev-bootstrap apply-dev-network ## Apply both stacks for dev
	@echo "$(GREEN)✓ Dev environment deployed$(NC)"

destroy-dev: ## Destroy dev environment (network first, then bootstrap)
	@echo "$(RED)Destroying dev environment...$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		echo "$(RED)Destroying network...$(NC)"; \
		cd stacks/network && $(TERRAFORM) destroy -var-file=../../envs/dev/network.tfvars; \
		echo "$(RED)Destroying bootstrap...$(NC)"; \
		cd stacks/bootstrap && $(TERRAFORM) destroy -var-file=../../envs/dev/bootstrap.tfvars; \
		echo "$(GREEN)✓ Dev environment destroyed$(NC)"; \
	else \
		echo "Cancelled."; \
	fi

# ============================================================================
# Production Environment
# ============================================================================

init-prod: ## Initialize Terraform for prod environment
	@echo "$(BLUE)Initializing prod environment...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) init
	@echo "$(GREEN)✓ Bootstrap initialized$(NC)"
	cd stacks/network && $(TERRAFORM) init -backend-config=../../envs/prod/network.backend.hcl
	@echo "$(GREEN)✓ Network initialized$(NC)"

plan-prod: ## Plan both bootstrap and network for prod
	@echo "$(BLUE)Planning bootstrap (prod)...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) plan -var-file=../../envs/prod/bootstrap.tfvars -out=bootstrap.tfplan
	@echo ""
	@echo "$(BLUE)Planning network (prod)...$(NC)"
	cd stacks/network && $(TERRAFORM) plan -var-file=../../envs/prod/network.tfvars -out=network.tfplan
	@echo ""
	@echo "$(GREEN)✓ Plans created (bootstrap.tfplan, network.tfplan)$(NC)"
	@echo "$(YELLOW)⚠ Review plans carefully before applying to production!$(NC)"

apply-prod-bootstrap: ## Apply bootstrap stack for prod
	@echo "$(RED)⚠ Applying bootstrap to PRODUCTION...$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		cd stacks/bootstrap && $(TERRAFORM) apply -var-file=../../envs/prod/bootstrap.tfvars; \
	else \
		echo "Cancelled."; \
	fi

apply-prod-network: ## Apply network stack for prod
	@echo "$(RED)⚠ Applying network to PRODUCTION...$(NC)"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		cd stacks/network && $(TERRAFORM) apply -var-file=../../envs/prod/network.tfvars; \
	else \
		echo "Cancelled."; \
	fi

apply-prod: apply-prod-bootstrap apply-prod-network ## Apply both stacks for prod (requires confirmation)
	@echo "$(GREEN)✓ Prod environment deployed$(NC)"

destroy-prod: ## Destroy prod environment (network first, then bootstrap)
	@echo "$(RED)WARNING: Destroying PRODUCTION environment!$(NC)"
	@read -p "Type 'destroy-prod' to confirm: " confirm; \
	if [ "$$confirm" = "destroy-prod" ]; then \
		echo "$(RED)Destroying network...$(NC)"; \
		cd stacks/network && $(TERRAFORM) destroy -var-file=../../envs/prod/network.tfvars; \
		echo "$(RED)Destroying bootstrap...$(NC)"; \
		cd stacks/bootstrap && $(TERRAFORM) destroy -var-file=../../envs/prod/bootstrap.tfvars; \
		echo "$(GREEN)✓ Prod environment destroyed$(NC)"; \
	else \
		echo "Cancelled."; \
	fi

# ============================================================================
# Utility Targets
# ============================================================================

clean: ## Remove Terraform files and caches
	@echo "$(BLUE)Cleaning Terraform files...$(NC)"
	find . -type d -name .terraform -exec rm -rf {} + 2>/dev/null || true
	find . -name .terraform.lock.hcl -delete
	find . -name *.tfplan -delete
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

state-list-dev: ## List resources in dev state
	@echo "$(BLUE)Resources in dev state:$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) state list
	cd stacks/network && $(TERRAFORM) state list

state-show-dev: ## Show dev state (use with STATE_PATH)
	@if [ -z "$(STATE_PATH)" ]; then \
		echo "$(RED)Usage: make state-show-dev STATE_PATH=<path>$(NC)"; \
		echo "Example: make state-show-dev STATE_PATH=aws_s3_bucket.terraform_state"; \
	else \
		$(TERRAFORM) state show "$(STATE_PATH)"; \
	fi

refresh-dev: ## Refresh dev state without making changes
	@echo "$(BLUE)Refreshing dev state...$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) refresh -var-file=../../envs/dev/bootstrap.tfvars
	cd stacks/network && $(TERRAFORM) refresh -var-file=../../envs/dev/network.tfvars
	@echo "$(GREEN)✓ State refreshed$(NC)"

output-dev: ## Show dev outputs
	@echo "$(BLUE)Bootstrap outputs:$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) output -no-color
	@echo ""
	@echo "$(BLUE)Network outputs:$(NC)"
	cd stacks/network && $(TERRAFORM) output -no-color

output-prod: ## Show prod outputs
	@echo "$(BLUE)Bootstrap outputs:$(NC)"
	cd stacks/bootstrap && $(TERRAFORM) output -no-color
	@echo ""
	@echo "$(BLUE)Network outputs:$(NC)"
	cd stacks/network && $(TERRAFORM) output -no-color

graph-dev: ## Generate resource graph for dev
	@echo "$(BLUE)Generating resource graph for dev...$(NC)"
	cd stacks/network && $(TERRAFORM) graph | dot -Tsvg > network-graph-dev.svg
	@echo "$(GREEN)✓ Graph saved to network-graph-dev.svg$(NC)"

# ============================================================================
# Documentation
# ============================================================================

docs: ## Show documentation paths
	@echo "$(BLUE)Documentation:$(NC)"
	@echo "  Architecture Decisions:"
	@echo "    docs/decisions/ADR-0001-backend-state.md"
	@echo "    docs/decisions/ADR-0002-naming-tags.md"
	@echo "    docs/decisions/ADR-0003-environments.md"
	@echo ""
	@echo "  Operational Guides:"
	@echo "    docs/runbooks/troubleshooting.md"
	@echo ""
	@echo "  Environment Guides:"
	@echo "    envs/dev/README.md"
	@echo "    envs/prod/README.md"

# ============================================================================
# Info
# ============================================================================

info: ## Show environment info
	@echo "$(BLUE)Environment Information:$(NC)"
	@echo "  Terraform version:"
	@$(TERRAFORM) version | head -1
	@echo ""
	@echo "  AWS account:"
	@aws sts get-caller-identity --query 'Account' --output text 2>/dev/null || echo "  Not configured"
	@echo ""
	@echo "  AWS region:"
	@aws configure get region 2>/dev/null || echo "  sa-east-1 (default)"
	@echo ""
	@echo "  Project: acme-landingzone"
