# AWS Terraform Landing Zone Template

Professional, production-ready Terraform template for provisioning AWS Landing Zones and foundational infrastructure. Designed for reuse across multiple clients with strong governance, security, and operational standards.

## 📋 Overview

This repository implements AWS infrastructure using Terraform with:
- **Two-stack architecture:** Bootstrap (state management) + Network (VPC/subnets)
- **Multi-environment support:** Dev and prod configurations with different security/HA settings
- **Professional governance:** Naming conventions, tagging standards, documented decisions
- **Operational excellence:** Troubleshooting runbooks, state recovery procedures, quality checks

## 🏗️ Architecture

### Stack 1: Bootstrap
Creates AWS infrastructure for managing Terraform state itself:
- **S3 bucket** with versioning, encryption, and public access blocked
- **DynamoDB table** for state locking (prevents concurrent modifications)
- **Bucket policy** protecting against accidental deletion
- **Lifecycle rules** expiring old state versions

### Stack 2: Network
Provisions foundation VPC infrastructure using Terraform AWS modules:
- **VPC** with customizable CIDR blocks
- **Public subnets** in multiple AZs with route to Internet Gateway
- **Private subnets** in multiple AZs with route to NAT Gateway
- **VPC endpoints** for S3 and DynamoDB (gateway endpoints)
- **Optional VPC Flow Logs** for security monitoring

## 📁 Directory Structure

```
.
├── stacks/
│   ├── bootstrap/          # S3 state bucket + DynamoDB locks
│   │   ├── versions.tf
│   │   ├── providers.tf
│   │   ├── locals.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── main.tf
│   └── network/            # VPC and networking
│       ├── versions.tf
│       ├── providers.tf
│       ├── locals.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── main.tf
├── envs/
│   ├── dev/                # Development environment config
│   │   ├── bootstrap.tfvars
│   │   ├── network.tfvars
│   │   ├── bootstrap.backend.hcl
│   │   ├── network.backend.hcl
│   │   └── README.md
│   └── prod/               # Production environment config
│       ├── bootstrap.tfvars
│       ├── network.tfvars
│       ├── bootstrap.backend.hcl
│       ├── network.backend.hcl
│       └── README.md
├── docs/
│   ├── decisions/          # Architecture Decision Records (ADRs)
│   │   ├── ADR-0001-backend-state.md
│   │   ├── ADR-0002-naming-tags.md
│   │   └── ADR-0003-environments.md
│   └── runbooks/           # Operational guides
│       └── troubleshooting.md
├── scripts/
│   ├── check.sh            # Format, validate, lint checks
│   └── init.sh             # Environment setup helper
├── .gitignore
├── .pre-commit-config.yaml # Git hooks for quality
├── Makefile                # Common task automation
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites
```bash
# Required
- Terraform >= 1.6
- AWS CLI >= 2.0
- AWS credentials configured (aws sts get-caller-identity works)

# Optional but recommended
- tfenv (Terraform version manager)
- Pre-commit (git hooks)
- tflint (Terraform linter)
```

### 1. Clone and Setup
```bash
git clone <repo-url>
cd aws-terraform-landingzone

# Install pre-commit hooks
pre-commit install

# Verify setup
make validate
```

### 2. Deploy Bootstrap (Creates State Backend)

```bash
cd stacks/bootstrap

# Initialize Terraform (uses local state initially)
terraform init

# Review changes
terraform plan -var-file=../../envs/dev/bootstrap.tfvars

# Create state bucket and DynamoDB lock table
terraform apply -var-file=../../envs/dev/bootstrap.tfvars
```

**Output:**
```
Outputs:
state_bucket_name = "tf-state-123456789-sa-east-1"
state_lock_table_name = "acme-landingzone-dev-locks"
```

### 3. Migrate Bootstrap State to Remote

```bash
cd stacks/bootstrap

# Reconfigure to use remote backend
terraform init \
  -backend-config=../../envs/dev/bootstrap.backend.hcl \
  -reconfigure
```

### 4. Deploy Network Stack

```bash
cd ../network

# Initialize with remote backend
terraform init \
  -backend-config=../../envs/dev/network.backend.hcl

# Plan and review
terraform plan -var-file=../../envs/dev/network.tfvars -out=dev.tfplan

# Apply
terraform apply dev.tfplan
```

**Output:**
```
Outputs:
vpc_id = "vpc-0123456789abcdef0"
public_subnets = ["subnet-001...", "subnet-002...", "subnet-003..."]
private_subnets = ["subnet-011...", "subnet-012...", "subnet-013..."]
nat_gateway_ips = ["203.0.113.1"]
```

### 5. For Production
Replace `dev` with `prod` in all commands above. Key differences:
- **Network:** HA with NAT Gateway per AZ (`single_nat_gateway = false`)
- **Observability:** VPC Flow Logs enabled (30-day retention)
- **Process:** Requires team approval before apply

See [envs/prod/README.md](envs/prod/README.md)

---

## 🏷️ Naming Convention & Tags

All resources follow the pattern:
```
<client>-<project>-<environment>-<resource-type>
```

Example: `acme-landingzone-dev-vpc`

### Default Tags (Applied Automatically)
| Tag | Example | Purpose |
|-----|---------|---------|
| Client | acme | Client name |
| Project | landingzone | Project name |
| Environment | dev, prod | Environment tier |
| Owner | joas@acme.com | Contact email |
| ManagedBy | Terraform | Infrastructure tool |
| Repository | aws-terraform-landingzone | Source repo |

Customize via variables in `stacks/*/variables.tf`

See [ADR-0002: Naming Convention and Tags](docs/decisions/ADR-0002-naming-tags.md)

---

## 🔒 Security Highlights

### State Management
- ✅ **Versioning enabled** - Recover from accidental deletions
- ✅ **Encryption at rest** - SSE-S3 by default, KMS optional
- ✅ **Locking mechanism** - DynamoDB prevents concurrent modifications
- ✅ **Bucket policy** - Denies DeleteBucket action
- ✅ **Public access blocked** - Block all public access

### Network
- ✅ **Private subnets** - Resources without direct internet access
- ✅ **NAT Gateway** - Secure outbound-only internet access
- ✅ **VPC endpoints** - Connect to AWS services without internet
- ✅ **Optional Flow Logs** - Monitor and audit network traffic
- ✅ **Default tags** - Compliance and cost allocation

### Terraform
- ✅ **No hardcoded secrets** - Use AWS IAM roles, not keys
- ✅ **Variable validation** - Environment must be dev/staging/prod
- ✅ **Provider constraints** - Terraform >= 1.6, AWS >= 5.0
- ✅ **Assume role support** - Cross-account deployments

See [ADR-0001: Backend State Management](docs/decisions/ADR-0001-backend-state.md)

---

## 📦 Variables & Customization

### Bootstrap Stack
```hcl
# Encryption
enable_encryption_kms = false              # Use KMS instead of SSE-S3
kms_key_arn = null                         # KMS key ARN if above true

# Versioning
enable_versioning = true                   # Keep state history
noncurrent_version_expiration_days = 90    # Clean up old versions

# Locking
enable_dynamodb_lock = true                # Create lock table
dynamodb_point_in_time_recovery = true     # Enable PITR
```

### Network Stack
```hcl
# Sizing
vpc_cidr = "10.0.0.0/16"                   # VPC network block
public_subnet_cidrs = ["10.0.1.0/24", ...]
private_subnet_cidrs = ["10.0.11.0/24", ...]

# HA/Cost
single_nat_gateway = true                  # false for HA (per-AZ NAT)
enable_nat_gateway = true                  # Disable to save costs

# Observability
enable_flow_logs = false                   # VPC Flow Logs to CloudWatch
flow_logs_retention_days = 7               # Log retention

# Endpoints
enable_s3_endpoint = true                  # S3 gateway endpoint
enable_dynamodb_endpoint = true            # DynamoDB gateway endpoint
```

Override via `-var-file=envs/ENV/STACK.tfvars`

---

## 🛠️ Make Targets

Convenient shortcuts for common tasks:

```bash
make validate              # Format check, validate, lint
make fmt                   # Auto-format all Terraform files
make validate-tf           # Terraform syntax validation
make lint                  # Run tflint (if installed)
make check-security        # tfsec security scan
make plan-dev              # Plan dev bootstrap + network
make apply-dev             # Apply dev bootstrap + network
make plan-prod             # Plan prod bootstrap + network
make apply-prod            # Apply prod bootstrap + network
make destroy-dev           # Destroy dev (bootstrap last)
make destroy-prod          # Destroy prod (bootstrap last)
```

Example:
```bash
make plan-dev              # Review changes
make apply-dev             # Deploy to dev
```

---

## 📚 Documentation

### Architecture Decisions
- [ADR-0001: Backend State](docs/decisions/ADR-0001-backend-state.md) - Why S3 + DynamoDB
- [ADR-0002: Naming & Tags](docs/decisions/ADR-0002-naming-tags.md) - Convention standards
- [ADR-0003: Environments](docs/decisions/ADR-0003-environments.md) - Multi-env strategy

### Operations Guides
- [Troubleshooting](docs/runbooks/troubleshooting.md) - Common issues and fixes
  - State lock stuck
  - Version mismatches
  - State recovery procedures
  - Permission denied errors

### Environment-Specific
- [Dev Guide](envs/dev/README.md) - How to deploy to development
- [Prod Guide](envs/prod/README.md) - How to deploy to production

---

## 🔄 CI/CD Integration

### Example: GitHub Actions
```yaml
name: Terraform Plan

on: [pull_request]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0
      
      - name: Validate
        run: make validate
      
      - name: Plan Dev
        run: make plan-dev
        env:
          AWS_REGION: sa-east-1
```

### Example: Manual Approval for Prod
```bash
# Plan without applying
make plan-prod

# After code review and approval
make apply-prod
```

---

## 🚨 Disaster Recovery

### State Bucket Deleted
1. **Create new bucket** with `terraform apply` (uses S3 versioning backup)
2. **Restore from version:**
   ```bash
   aws s3api get-object \
     --bucket <bucket> \
     --key terraform.tfstate \
     --version-id <VERSION_ID> \
     terraform.tfstate
   ```
3. **Re-upload:** `terraform state push terraform.tfstate`

See [Troubleshooting: Recover Previous State](docs/runbooks/troubleshooting.md#4-recover-previous-infrastructure-state)

### Entire Infrastructure Gone
Thanks to state versioning:
1. List available versions in S3
2. Download backup state
3. Run `terraform plan` to see what changed
4. Manually remediate or replay state version

---

## 🎯 For New Customers

### Personalization Checklist
1. **Clone this template**
2. **Update parameters:**
   ```bash
   CLIENT="customer-name"
   PROJECT="workload-name"
   OWNER="owner@customer.com"
   ```
3. **Create environment files:** `envs/{dev,prod}/*.tfvars`
4. **Deploy bootstrap:** `cd stacks/bootstrap && terraform apply`
5. **Deploy network:** `cd ../network && terraform apply`
6. **Add to customer repo** and share access

### Common Extensions
- Add security stack (SecurityHub, GuardDuty, Config)
- Add logging stack (CloudTrail, S3 buckets, centralized logs)
- Add observability stack (CloudWatch dashboards, SNS alerts)
- Add identity stack (Organizations, SSO, cross-account roles)

---

## 🤝 Contributing

1. **Branch:** Create feature branch `feature/add-security-stack`
2. **Validate:** `make validate`
3. **Test:** Deploy to dev environment
4. **PR:** Submit with Terraform plan output
5. **Review:** Require team approval
6. **Merge & Deploy:** Push to main, deploy to prod via pipeline

---

## 📝 License & Support

This is a template for professional use. Customize and extend for your needs.

For issues:
1. Check [Troubleshooting Guide](docs/runbooks/troubleshooting.md)
2. Review [Architecture Decisions](docs/decisions/)
3. Contact infrastructure team

---

## 🗺️ Roadmap

- [ ] Security stack (SecurityHub, GuardDuty, Config rules)
- [ ] Logging stack (CloudTrail, centralized logs, retention)
- [ ] Observability stack (CloudWatch, SNS, dashboards)
- [ ] Identity stack (Organizations, SSO, cross-account)
- [ ] Database stack (RDS, DocumentDB, examples)
- [ ] Compute stack (ECS, Lambda, EC2, examples)
- [ ] CI/CD pipeline stack (CodePipeline, CodeBuild, examples)
