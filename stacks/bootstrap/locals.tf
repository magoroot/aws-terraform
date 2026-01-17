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
