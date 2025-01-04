data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.project}-${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  private_subnets = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets  = [for i in range(2) : cidrsubnet(var.vpc_cidr, 8, i + 100)]

  enable_nat_gateway = false

  # VPCエンドポイントの設定
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

# ECR API エンドポイント
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name        = "${var.project}-${var.environment}-ecr-api-endpoint"
    Environment = var.environment
    Project     = var.project
  }
}

# ECR DKR エンドポイント
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name        = "${var.project}-${var.environment}-ecr-dkr-endpoint"
    Environment = var.environment
    Project     = var.project
  }
}

# CloudWatch Logs エンドポイント
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = module.vpc.private_subnets
  security_group_ids  = [aws_security_group.vpc_endpoints.id]

  tags = {
    Name        = "${var.project}-${var.environment}-logs-endpoint"
    Environment = var.environment
    Project     = var.project
  }
}

# S3 エンドポイント（ECRが必要とする）
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids

  tags = {
    Name        = "${var.project}-${var.environment}-s3-endpoint"
    Environment = var.environment
    Project     = var.project
  }
}

# VPCエンドポイント用のセキュリティグループ
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-${var.environment}-vpc-endpoints"
  description = "Security group for VPC endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  tags = {
    Name        = "${var.project}-${var.environment}-vpc-endpoints"
    Environment = var.environment
    Project     = var.project
  }
}
