# ADR 0003: Environment Strategy

**Date:** 2026-01-17
**Status:** Accepted

## Context
Multiple environments (dev, staging, prod) require different configurations, but maintaining separate Terraform repositories would cause duplication and drift. A single codebase must support multiple environments safely.

## Decision
Use **stack-based architecture** with **tfvars files per environment**:

### Directory Structure
```
stacks/
├── bootstrap/          # Shared bootstrap (S3 state, DynamoDB locks)
└── network/            # Shared network configuration

envs/
├── dev/
│   ├── bootstrap.tfvars
│   ├── network.tfvars
│   ├── bootstrap.backend.hcl
│   └── network.backend.hcl
└── prod/
    ├── bootstrap.tfvars
    ├── network.tfvars
    ├── bootstrap.backend.hcl
    └── network.backend.hcl
```

### Execution Pattern
```bash
# Bootstrap (creates state backend)
cd stacks/bootstrap
terraform init
terraform plan -var-file=../../envs/dev/bootstrap.tfvars
terraform apply -var-file=../../envs/dev/bootstrap.tfvars

# Network
cd ../network
terraform init -backend-config=../../envs/dev/network.backend.hcl
terraform plan -var-file=../../envs/dev/network.tfvars
terraform apply -var-file=../../envs/dev/network.tfvars
```

### Variable Override Pattern
**stacks/bootstrap/variables.tf** defines defaults:
```hcl
variable "environment" {
  default = "dev"
}

variable "single_nat_gateway" {
  default = true  # Cost optimization for dev
}
```

**envs/prod/network.tfvars** overrides:
```hcl
environment = "prod"
single_nat_gateway = false  # HA for prod
enable_flow_logs = true
```

## Consequences
### Positive
- Single source of truth for infrastructure code
- Environment differences managed via variables (not branching)
- Easy to promote changes from dev to prod
- Clear separation between bootstrap and per-stack concerns
- Each environment has isolated state in S3

### Negative
- Must remember `-var-file` flag (mitigated by Makefile)
- Requires discipline to not hardcode values
- Backend must be initialized separately per environment

## Related Decisions
- ADR 0001: Backend State Management
- ADR 0002: Naming Convention and Tags

## How to Add New Environment
1. Copy `envs/dev/` to `envs/staging/`
2. Update `.tfvars` files with staging values
3. Run bootstrap and network stacks with new tfvars
4. Update CI/CD pipeline to include staging
