# Development Environment

## Overview
This directory contains configuration files for the **development** environment.

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
terraform init -backend-config=../../envs/dev/bootstrap.backend.hcl -reconfigure

# Plan
terraform plan -var-file=../../envs/dev/bootstrap.tfvars

# Apply
terraform apply -var-file=../../envs/dev/bootstrap.tfvars
```

### 2. Initialize Network Stack
After bootstrap is complete:

```bash
cd stacks/network

# Init with backend from bootstrap output
terraform init -backend-config=../../envs/dev/network.backend.hcl

# Plan
terraform plan -var-file=../../envs/dev/network.tfvars

# Apply
terraform apply -var-file=../../envs/dev/network.tfvars
```

## Variables
See `stacks/bootstrap/variables.tf` and `stacks/network/variables.tf` for all available options.

### Key Dev Overrides
- Single NAT Gateway (cost optimization)
- Flow logs disabled by default
- 90-day expiration for old state versions

## Troubleshooting
See [docs/runbooks/troubleshooting.md](../../docs/runbooks/troubleshooting.md)
