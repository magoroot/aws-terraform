# ADR 0001: Backend State Management

**Date:** 2026-01-17
**Status:** Accepted

## Context
Terraform state is critical infrastructure data that must be protected, versioned, and backed up. A single misconfiguration or accidental deletion can compromise the entire infrastructure.

## Decision
Use AWS S3 for remote state storage with:
- **Versioning enabled** - allows recovery of previous infrastructure states
- **SSE-S3 encryption** - ensures state data is encrypted at rest (default)
- **SSE-KMS option** - for customers requiring KMS-managed keys
- **DynamoDB lock table** - prevents concurrent modifications that could corrupt state
- **Bucket policy** - explicitly denies DeleteBucket to prevent accidental destruction
- **Lifecycle rules** - expires noncurrent versions after 90 days to manage costs

## Consequences
### Positive
- State is durable and survives local machine failures
- Versioning enables rollback to previous infrastructure versions
- Locking prevents race conditions in CI/CD pipelines
- Encryption protects sensitive data (passwords, keys, etc.)
- Cost-effective (S3 + DynamoDB are ~$5-10/month)

### Negative
- Requires AWS CLI credentials to initialize
- Network latency when reading/writing state (minimal impact)
- Requires care when migrating state between AWS accounts

## Implementation
See [stacks/bootstrap/main.tf](../../stacks/bootstrap/main.tf)

Run bootstrap stack first:
```bash
cd stacks/bootstrap
terraform init
terraform plan -var-file=../../envs/dev/bootstrap.tfvars
terraform apply -var-file=../../envs/dev/bootstrap.tfvars
```

After bootstrap, migrate local state to remote:
```bash
terraform init -backend-config=../../envs/dev/bootstrap.backend.hcl -reconfigure
```
