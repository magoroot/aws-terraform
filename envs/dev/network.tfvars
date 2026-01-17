client_name           = "acme"
project_name          = "landingzone"
environment           = "dev"
owner_email           = "joas@acme.com"
repository_name       = "aws-terraform-landingzone"

vpc_cidr              = "10.0.0.0/16"
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

enable_nat_gateway    = true
single_nat_gateway    = true
enable_vpn_gateway    = false

enable_s3_endpoint    = true
enable_dynamodb_endpoint = true

enable_flow_logs      = false
flow_logs_retention_days = 7
