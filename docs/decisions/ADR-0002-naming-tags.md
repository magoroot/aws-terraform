# ADR 0002: Naming Convention and Tags

**Date:** 2026-01-17
**Status:** Accepted

## Context
Infrastructure managed by multiple teams across different projects requires consistent naming and tagging for:
- Resource identification and discovery
- Cost allocation and billing
- Compliance and audit trails
- Automation and scripts

## Decision
Use hierarchical naming pattern with standardized tags:

### Naming Pattern
```
<client>-<project>-<environment>-<resource-type>[-identifier]
```

Examples:
- `acme-landingzone-dev-vpc`
- `acme-landingzone-prod-nat-gateway-1a`

### Required Tags (All Resources)
| Tag | Example | Purpose |
|-----|---------|---------|
| `Client` | `acme` | Which client owns this |
| `Project` | `landingzone` | Which project/workload |
| `Environment` | `dev`, `prod` | Environment classification |
| `Owner` | `joas@acme.com` | Contact for escalations |
| `ManagedBy` | `Terraform` | Infrastructure as code tool |
| `Repository` | `aws-terraform-landingzone` | Source code repository |

### Implementation in Terraform
Local variables automatically apply tags via `default_tags`:

```hcl
locals {
  name_prefix = "${var.client_name}-${var.project_name}-${var.environment}"

  default_tags = {
    Client     = var.client_name
    Project    = var.project_name
    Environment = var.environment
    Owner      = var.owner_email
    ManagedBy  = "Terraform"
    Repository = var.repository_name
  }
}
```

Provider configuration applies these automatically:
```hcl
provider "aws" {
  default_tags {
    tags = local.default_tags
  }
}
```

## Consequences
### Positive
- Easy to identify resources by client/project/environment
- Enables automated cost allocation
- Supports access control policies
- Simplifies disaster recovery procedures

### Negative
- Requires discipline to not skip tags
- Tag keys must not exceed 128 characters

## Related Files
- [stacks/bootstrap/locals.tf](../../stacks/bootstrap/locals.tf)
- [stacks/network/locals.tf](../../stacks/network/locals.tf)
