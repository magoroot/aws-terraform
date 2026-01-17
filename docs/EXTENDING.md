# Exemplo: Adicionar Novo Stack ao Template

## Estrutura de um Stack

Cada stack deve seguir este padrão:

```
stacks/my-new-stack/
├── versions.tf          (requirements de versão)
├── providers.tf         (provider configuration)
├── locals.tf            (naming + default_tags)
├── variables.tf         (inputs)
├── main.tf              (resources)
└── outputs.tf           (outputs)
```

## Exemplo: Criar Stack de Logging

### 1. Criar diretório

```bash
mkdir -p stacks/logging
```

### 2. versions.tf

```hcl
terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### 3. providers.tf

```hcl
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.default_tags
  }

  dynamic "assume_role" {
    for_each = var.assume_role_arn != null ? [1] : []
    content {
      role_arn = var.assume_role_arn
    }
  }
}
```

### 4. locals.tf

```hcl
locals {
  name_prefix = "${var.client_name}-${var.project_name}-${var.environment}"

  default_tags = {
    Client      = var.client_name
    Project     = var.project_name
    Environment = var.environment
    Owner       = var.owner_email
    ManagedBy   = "Terraform"
    Repository  = var.repository_name
  }
}
```

### 5. variables.tf

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "default"
}

variable "assume_role_arn" {
  description = "ARN of role to assume (optional)"
  type        = string
  default     = null
}

variable "client_name" {
  description = "Client name for naming and tags"
  type        = string
  default     = "acme"
}

variable "project_name" {
  description = "Project name for naming and tags"
  type        = string
  default     = "landingzone"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "owner_email" {
  description = "Owner email for tags"
  type        = string
  default     = "joas@acme.com"
}

variable "repository_name" {
  description = "Repository name for tags"
  type        = string
  default     = "aws-terraform-landingzone"
}

# Stack-specific variables
variable "cloudtrail_bucket_prefix" {
  description = "S3 bucket prefix for CloudTrail logs"
  type        = string
  default     = "cloudtrail"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for audit logging"
  type        = bool
  default     = true
}
```

### 6. main.tf

```hcl
# S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = "${var.cloudtrail_bucket_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  tags = {
    Name = "${local.name_prefix}-cloudtrail"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count  = var.enable_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy[0].json
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  count = var.enable_cloudtrail ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      service = "cloudtrail.amazonaws.com"
    }
    actions = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail[0].arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      service = "cloudtrail.amazonaws.com"
    }
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail[0].arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

data "aws_caller_identity" "current" {}
```

### 7. outputs.tf

```hcl
output "cloudtrail_bucket_name" {
  description = "Name of CloudTrail S3 bucket"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].id : null
}

output "cloudtrail_bucket_arn" {
  description = "ARN of CloudTrail S3 bucket"
  value       = var.enable_cloudtrail ? aws_s3_bucket.cloudtrail[0].arn : null
}
```

## 3. Adicionar variáveis de ambiente

### envs/dev/logging.tfvars

```hcl
client_name = "acme"
project_name = "landingzone"
environment = "dev"
owner_email = "joas@acme.com"
repository_name = "aws-terraform-landingzone"

cloudtrail_bucket_prefix = "cloudtrail"
log_retention_days = 7
enable_cloudtrail = true
```

### envs/prod/logging.tfvars

```hcl
client_name = "acme"
project_name = "landingzone"
environment = "prod"
owner_email = "joas@acme.com"
repository_name = "aws-terraform-landingzone"

cloudtrail_bucket_prefix = "cloudtrail"
log_retention_days = 365
enable_cloudtrail = true
```

## 4. Adicionar backend.hcl

### envs/dev/logging.backend.hcl

```hcl
skip_region_validation = false
skip_credentials_validation = false
skip_metadata_api_check = false
```

## 5. Atualizar Makefile

Adicione targets para o novo stack:

```makefile
plan-logging-dev:
  @echo "$(BLUE)Planning logging (dev)...$(NC)"
  cd stacks/logging && $(TERRAFORM) plan -var-file=../../envs/dev/logging.tfvars

apply-logging-dev:
  @echo "$(BLUE)Applying logging (dev)...$(NC)"
  cd stacks/logging && $(TERRAFORM) apply -var-file=../../envs/dev/logging.tfvars

destroy-logging-dev:
  @echo "$(RED)Destroying logging (dev)...$(NC)"
  cd stacks/logging && $(TERRAFORM) destroy -var-file=../../envs/dev/logging.tfvars
```

## 6. Deploy

```bash
# Initialize
cd stacks/logging
terraform init -backend-config=../../envs/dev/logging.backend.hcl

# Plan
terraform plan -var-file=../../envs/dev/logging.tfvars

# Apply
terraform apply -var-file=../../envs/dev/logging.tfvars

# View outputs
terraform output
```

## Padrão de Nomenclatura

Mantenha consistência:

- **Variáveis globais:** aws_region, aws_profile, client_name, project_name, environment, owner_email, repository_name
- **Variáveis de stack:** prefixadas com significado (cloudtrail_bucket_prefix, log_retention_days, enable_*)
- **Nome de resource:** ${local.name_prefix}-<resource-type> 
  - Ex: acme-landingzone-dev-cloudtrail

## Boas Práticas

✅ **DO:**
- Usar variáveis para tudo que pode mudar
- Incluir descrição em todas as variáveis
- Validar inputs (enums, ranges)
- Usar default_tags
- Manter 6 arquivos padrão
- Usar terraform-aws-modules quando disponível
- Documentar no README

❌ **DON'T:**
- Hardcod valores
- Misturar responsabilidades de stacks
- Sem validação de variáveis
- Tags manuais (usar default_tags)
- Adicionar lógica complexa em main.tf sem comentários
- Secrets em código (usar AWS Secrets Manager)

## Próximo passo

Depois de criar seu novo stack, documente no README e ADR explicando por que foi criado.
