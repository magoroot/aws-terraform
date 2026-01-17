variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "sa-east-1"
}

variable "aws_profile" {
  description = "AWS profile name to use"
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

variable "state_bucket_prefix" {
  description = "Prefix for S3 bucket name (full name will be prefixed-state-<account>-<region>)"
  type        = string
  default     = "tf"
}

variable "enable_versioning" {
  description = "Enable versioning for state bucket"
  type        = bool
  default     = true
}

variable "enable_encryption_kms" {
  description = "Use KMS encryption instead of SSE-S3"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of KMS key for encryption (required if enable_encryption_kms=true)"
  type        = string
  default     = null
}

variable "noncurrent_version_expiration_days" {
  description = "Expire noncurrent versions after N days (0 to disable)"
  type        = number
  default     = 90
}

variable "enable_dynamodb_lock" {
  description = "Create DynamoDB table for state locking"
  type        = bool
  default     = true
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable DynamoDB point-in-time recovery"
  type        = bool
  default     = true
}
