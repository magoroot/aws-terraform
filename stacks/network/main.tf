module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = false

  enable_vpn_gateway = var.enable_vpn_gateway

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  public_subnet_tags = {
    Type = "Public"
  }

  private_subnet_tags = {
    Type = "Private"
  }

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_flow_logs_log_group" "vpc" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/flowlogs/${local.name_prefix}"
  retention_in_days = var.flow_logs_retention_days
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-vpc-flowlogs-policy"
  role  = aws_iam_role.vpc_flow_logs_role[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = aws_flow_logs_log_group.vpc[0].arn
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  count                = var.enable_flow_logs ? 1 : 0
  iam_role_arn         = aws_iam_role.vpc_flow_logs_role[0].arn
  log_destination      = aws_flow_logs_log_group.vpc[0].arn
  traffic_type         = "ALL"
  vpc_id               = module.vpc.vpc_id
  log_destination_type = "cloud-watch-logs"
  log_format           = "${local.name_prefix}-vpc-flowlogs"
}

data "aws_availability_zones" "available" {
  state = "available"
}
