output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.arn
}

output "state_lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = var.enable_dynamodb_lock ? aws_dynamodb_table.terraform_locks[0].id : null
}

output "state_lock_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = var.enable_dynamodb_lock ? aws_dynamodb_table.terraform_locks[0].arn : null
}

output "backend_config" {
  description = "Backend configuration for terraform init"
  value = {
    bucket         = aws_s3_bucket.terraform_state.id
    dynamodb_table = var.enable_dynamodb_lock ? aws_dynamodb_table.terraform_locks[0].id : null
    region         = var.aws_region
    encrypt        = true
  }
}
