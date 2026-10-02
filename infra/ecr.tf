# One ECR repository shared by all environments so the *same digest* can be
# promoted dev -> stage -> prod. The environment with create_ecr_repository = true
# (dev) owns the repo; the others only look the repo up.
#
# If your environments live in separate AWS accounts, keep the repo in a shared
# "tooling" account and add a repository policy allowing the env accounts to pull.

resource "aws_ecr_repository" "this" {
  count = var.create_ecr_repository ? 1 : 0

  name                 = var.service_name
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  count = var.create_ecr_repository ? 1 : 0

  repository = aws_ecr_repository.this[0].name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep the last 20 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 20
      }
      action = { type = "expire" }
    }]
  })
}

data "aws_ecr_repository" "existing" {
  count = var.create_ecr_repository ? 0 : 1
  name  = var.service_name
}

locals {
  name           = "${var.service_name}-${var.environment}"
  ssm_prefix     = "/services/${var.service_name}/${var.environment}"
  ecr_repo_url   = var.create_ecr_repository ? aws_ecr_repository.this[0].repository_url : data.aws_ecr_repository.existing[0].repository_url
  ecr_repo_arn   = var.create_ecr_repository ? aws_ecr_repository.this[0].arn : data.aws_ecr_repository.existing[0].arn
  bootstrapping  = var.image_digest == ""
  image          = local.bootstrapping ? "${local.ecr_repo_url}:bootstrap" : "${local.ecr_repo_url}@${var.image_digest}"
  container_name = var.service_name
}
