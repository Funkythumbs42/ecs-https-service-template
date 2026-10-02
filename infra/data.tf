data "aws_caller_identity" "current" {}

data "aws_ecs_cluster" "this" {
  cluster_name = var.cluster_name
}

data "aws_vpc" "this" {
  id = var.vpc_id != "" ? var.vpc_id : null

  dynamic "filter" {
    for_each = var.vpc_id == "" ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.vpc_tag_name]
    }
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = var.public_subnet_tags
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = var.private_subnet_tags
}

data "aws_route53_zone" "this" {
  name         = var.hosted_zone_name
  private_zone = false
}
