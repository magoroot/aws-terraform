#!/usr/bin/env bash

# Quick reference script for the AWS Terraform Landing Zone template

cat << 'EOF'

╔════════════════════════════════════════════════════════════════════════════╗
║        AWS TERRAFORM LANDING ZONE - QUICK START REFERENCE                 ║
╚════════════════════════════════════════════════════════════════════════════╝

📦 FIRST TIME SETUP
─────────────────────────────────────────────────────────────────────────────

1. Install Terraform >= 1.6:
   brew install terraform  (macOS)
   apt-get install terraform  (Linux)

2. Install AWS CLI >= 2.0:
   brew install awscliv2  (macOS)

3. Configure AWS credentials:
   aws configure
   # Enter: Access Key ID, Secret Access Key, Region (sa-east-1), Output (json)

4. Verify setup:
   terraform -version
   aws sts get-caller-identity

5. Install optional tools:
   brew install tflint tfsec pre-commit

6. Set up git hooks:
   pre-commit install

📋 DEPLOY DEVELOPMENT ENVIRONMENT
─────────────────────────────────────────────────────────────────────────────

Step 1: Bootstrap (Creates S3 state bucket + DynamoDB locks)

  cd stacks/bootstrap
  terraform init
  terraform plan -var-file=../../envs/dev/bootstrap.tfvars
  terraform apply -var-file=../../envs/dev/bootstrap.tfvars

Step 2: Migrate bootstrap state to remote

  terraform init \
    -backend-config=../../envs/dev/bootstrap.backend.hcl \
    -reconfigure

Step 3: Deploy Network (VPC, subnets, NAT, endpoints)

  cd ../network
  terraform init -backend-config=../../envs/dev/network.backend.hcl
  terraform plan -var-file=../../envs/dev/network.tfvars
  terraform apply -var-file=../../envs/dev/network.tfvars

⚡ USING MAKEFILE (RECOMMENDED)
─────────────────────────────────────────────────────────────────────────────

make help              # Show all targets
make validate          # Format, validate, lint
make plan-dev          # Plan both stacks for dev
make apply-dev         # Deploy both stacks for dev
make destroy-dev       # Destroy both stacks for dev

🏭 DEPLOY PRODUCTION ENVIRONMENT
─────────────────────────────────────────────────────────────────────────────

Replace 'dev' with 'prod' in all commands above:

  make plan-prod        # Plan production (requires careful review)
  make apply-prod       # Deploy production (requires confirmation)

⚠️  Key difference: Prod has HA NAT (per-AZ) and VPC Flow Logs enabled

📚 DOCUMENTATION
─────────────────────────────────────────────────────────────────────────────

README.md              # Project overview and architecture
envs/dev/README.md     # Dev environment guide
envs/prod/README.md    # Prod environment guide

docs/decisions/
  ADR-0001-backend-state.md  # Why S3 + DynamoDB
  ADR-0002-naming-tags.md    # Naming conventions
  ADR-0003-environments.md   # Multi-environment strategy

docs/runbooks/
  troubleshooting.md         # Common issues and fixes

🔧 CUSTOMIZE FOR YOUR CLIENT
─────────────────────────────────────────────────────────────────────────────

1. Update envs/dev/bootstrap.tfvars:
   client_name = "your-client"
   project_name = "your-project"
   owner_email = "owner@company.com"
   repository_name = "your-repo-name"

2. Update envs/dev/network.tfvars:
   vpc_cidr = "10.0.0.0/16"  (adjust as needed)
   public_subnet_cidrs = ["10.0.1.0/24", ...]
   private_subnet_cidrs = ["10.0.11.0/24", ...]

3. Create prod environment (copy from dev and adjust):
   cp envs/dev/*.tfvars envs/prod/
   cp envs/dev/*.hcl envs/prod/
   # Edit envs/prod/*.tfvars to change:
   #   environment = "prod"
   #   single_nat_gateway = false  (HA)
   #   enable_flow_logs = true

🚨 TROUBLESHOOTING
─────────────────────────────────────────────────────────────────────────────

State lock stuck?
  terraform force-unlock <LOCK_ID>

State version mismatch?
  Check: aws s3 cp s3://<bucket>/terraform.tfstate - | jq '.terraform_version'

Permission denied errors?
  Verify IAM user has: s3:*, dynamodb:CreateTable, sts:AssumeRole

Forgot backend config?
  cd stacks/bootstrap
  terraform init -reconfigure

Full troubleshooting: See docs/runbooks/troubleshooting.md

🔐 IAM PERMISSIONS REQUIRED
─────────────────────────────────────────────────────────────────────────────

Minimal IAM policy for deployment user:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:*",
        "dynamodb:*",
        "ec2:*",
        "logs:*",
        "iam:*",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}

For production: Add cloudtrail:LookupEvents, approve changes before apply

📊 PROJECT STRUCTURE
─────────────────────────────────────────────────────────────────────────────

stacks/
  bootstrap/    - S3 state bucket + DynamoDB locks (run first)
  network/      - VPC, subnets, NAT, endpoints (run second)

envs/
  dev/          - Development environment vars and backend config
  prod/         - Production environment vars and backend config

docs/
  decisions/    - Architecture Decision Records (ADRs)
  runbooks/     - Operational guides and troubleshooting

scripts/
  check.sh      - Quality checks (format, validate, lint)
  init.sh       - Interactive environment initialization

modules/       - Reusable Terraform modules (extend as needed)
templates/     - CloudInit, UserData, Lambda ZIP templates
files/         - Static files, configs, scripts

🎯 NEXT STEPS AFTER DEPLOYMENT
─────────────────────────────────────────────────────────────────────────────

1. Extend with more stacks:
   - Security (SecurityHub, Config, CloudTrail)
   - Logging (centralized CloudTrail, ELB logs)
   - Observability (CloudWatch dashboards, SNS)
   - Identity (Organizations, SSO, cross-account roles)

2. Set up CI/CD pipeline:
   - GitHub Actions / GitLab CI for plan/apply
   - Approval workflow for production

3. Add example workloads:
   - RDS databases
   - ECS clusters
   - Lambda functions
   - Application Load Balancers

See README.md for roadmap and contributing guidelines.

════════════════════════════════════════════════════════════════════════════

EOF
