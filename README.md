# winserv Terraform

Infrastructure for Windows AVD environment using Terraform with an Azure remote backend provided via environment-specific `backend.config` files.

## Backend Configuration
The `terraform` block omits an inline backend so you can supply it per environment:

Example `workspace/dev/backend.config`:
```
resource_group_name  = "rg-tfstate-shared"
storage_account_name = "sttfstatewinda123"
container_name       = "tfstate"
key                  = "dev-infra.tfstate"
use_azuread_auth     = true
```

Notes:
- Keys must be unique per environment (e.g., `dev-infra.tfstate`, `prod-infra.tfstate`).
- Do not use Terraform variables inside a backend config file; only literal values or environment variable interpolation performed by your shell before running `terraform init`.
- Ensure your principal has at least `Storage Blob Data Contributor` on the storage account when using AAD auth.

### Azure Login / Subscription Selection
Authenticate before running Make targets:

```bash
az login                                 # interactive login
az login --tenant <tenant_id>            # if multiple tenants
az account set -s <subscription_id_or_name>
az account show -o table                 # verify context
```

The Makefile will fail fast if no active Azure session is detected.

## Makefile Workflow
Common commands:
```
make init ENV=dev
make plan ENV=dev
make apply ENV=dev
make destroy ENV=dev
```
If an optional `workspace/<env>/terraform.tfvars` exists, it will be passed automatically.

## Adding a New Environment
1. Create directory: `workspace/<env>/`
2. Copy or create `backend.config` with correct RG, Storage Account, container, and key.
3. (Optional) Add `terraform.tfvars` for variable overrides.
4. Run `make init ENV=<env>`.

## Formatting & Validation
```
make fmt
make validate ENV=dev
```

## Cleaning Local Artifacts
`make clean` removes any stray local state artifacts if you accidentally initialized without backend.

## Troubleshooting
- Backend auth errors: run `az login` and ensure the correct subscription (`az account set -s <subscription>`).
- 403 AuthorizationPermissionMismatch: Assign a data plane role like `Storage Blob Data Contributor` to your principal on the storage account (control-plane roles alone are insufficient with `use_azuread_auth = true`).
- State lock issues: Azure backend uses blob leases; if a stuck lock occurs, release it by deleting the lease via portal/CLI (rare).
- Changed backend parameters: Re-run `make init ENV=dev` (will prompt to migrate if key changed).

## Future Improvements
- Add a bootstrap Terraform stack to provision the remote state RG/storage automatically.
- Introduce Terragrunt or environment promotion pipelines.
- Add CI workflow for `terraform fmt -check` and `terraform validate`.
