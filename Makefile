# Simple Terraform workflow Makefile
## Usage examples:
#   make init ENV=dev
#   make plan ENV=dev
#   make apply ENV=dev
#   make destroy ENV=dev
#
# Performs a lightweight Azure login check before Terraform init (via `az account show`).

# Default environment
ENV ?= dev
TF_DIR := src
WORKSPACE_DIR := ../workspace/$(ENV)
BACKEND_CONFIG := $(WORKSPACE_DIR)/backend.config

# Optionally allow a tfvars file per env (e.g., workspace/dev/terraform.tfvars)
VARS_FILE := $(WORKSPACE_DIR)/terraform.tfvars
VARS_FLAG := $(if $(wildcard $(VARS_FILE)),-var-file=$(VARS_FILE),)

.PHONY: init plan apply destroy show fmt validate outputs clean

# Azure CLI presence check
AZ ?= $(shell command -v az 2>/dev/null)
ifndef AZ
$(error Azure CLI 'az' not found in PATH. Install Azure CLI before running Terraform targets.)
endif

# Detect active subscription (empty if not logged in)
AZ_SUB_ID := $(shell az account show --query id -o tsv 2>/dev/null)

define ensure-az-login
	@if [ -z "$(AZ_SUB_ID)" ]; then \
		echo "[AZ LOGIN] No active Azure CLI session detected. Run: az login (or az login --tenant <tenant_id>) then az account set -s <subscription>."; \
		exit 1; \
	fi
endef

init:
	$(call ensure-az-login)
	terraform -chdir=$(TF_DIR) init -upgrade -backend-config=$(BACKEND_CONFIG)

plan: init
	terraform -chdir=$(TF_DIR) plan -var-file=$(VARS_FILE)

plan-save: init
	terraform -chdir=$(TF_DIR) plan -out=tfplan -var-file=$(VARS_FILE)

apply: init
	terraform -chdir=$(TF_DIR) apply -auto-approve -var-file=$(VARS_FILE)

destroy: init
	terraform -chdir=$(TF_DIR) destroy -auto-approve -var-file=$(VARS_FILE)

show:
	terraform -chdir=$(TF_DIR) show

fmt:
	terraform -chdir=$(TF_DIR) fmt -recursive

validate: init
	terraform -chdir=$(TF_DIR) validate

outputs:
	terraform -chdir=$(TF_DIR) output

clean:
	find $(TF_DIR) -name '*.tfstate*' -delete
	find $(TF_DIR) -name '.terraform' -type d -exec rm -rf {} +
