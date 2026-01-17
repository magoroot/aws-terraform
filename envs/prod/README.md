# Production Environment

## Overview
This directory contains configuration files for the **production** environment.

## Files
- `bootstrap.tfvars` - Variables for the bootstrap stack (S3 state bucket, DynamoDB locks)
- `network.tfvars` - Variables for the network stack (VPC, subnets, NAT)
- `bootstrap.backend.hcl` - Backend configuration for bootstrap stack init
- `network.backend.hcl` - Backend configuration for network stack init

## How to Run

### 1. Initialize Bootstrap Stack
```bash
cd stacks/bootstrap

# First time init without backend (local state)
terraform init

# After bootstrap runs, reconfigure to use remote backend
terraform init -backend-config=../../envs/prod/bootstrap.backend.hcl -reconfigure

# Plan
terraform plan -var-file=../../envs/prod/bootstrap.tfvars

# Apply
terraform apply -var-file=../../envs/prod/bootstrap.tfvars
```

### 2. Initialize Network Stack
After bootstrap is complete:

```bash
cd stacks/network

# Init with backend from bootstrap output
terraform init -backend-config=../../envs/prod/network.backend.hcl

# Plan
terraform plan -var-file=../../envs/prod/network.tfvars

# Apply
terraform apply -var-file=../../envs/prod/network.tfvars
```

## Variables
See `stacks/bootstrap/variables.tf` and `stacks/network/variables.tf` for all available options.

### Key Prod Overrides
- NAT Gateway per availability zone (HA)
- VPC Flow Logs enabled (30-day retention)
- Enhanced monitoring and security

## Troubleshooting
See [docs/runbooks/troubleshooting.md](../../docs/runbooks/troubleshooting.md)

## Approval Process
⚠️ **Production changes require approval before apply**

1. Create feature branch
2. Run `make plan-prod` and review carefully
3. Create PR with Terraform plan output
4. Require team approval
5. After approval, run `make apply-prod`
