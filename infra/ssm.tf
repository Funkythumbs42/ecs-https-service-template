# Publish values the pipelines (and other consumers) need, under
# /services/<service_name>/<env>/...
#
# NOTE: /services/<service_name>/<env>/image-digest is deliberately NOT managed
# here. The value is written by the app pipeline (scripts/deploy.sh) after a successful
# deploy, and read by scripts/tf-plan.sh so infra applies keep the running image.

locals {
  published = {
    "ecr-repository-url" = local.ecr_repo_url
    "cluster-name"       = data.aws_ecs_cluster.this.cluster_name
    "service-name"       = aws_ecs_service.this.name
    "task-family"        = aws_ecs_task_definition.this.family
    "container-name"     = local.container_name
    "url"                = "https://${var.domain_name}"
  }
}

resource "aws_ssm_parameter" "published" {
  for_each = local.published

  name  = "${local.ssm_prefix}/${each.key}"
  type  = "String"
  value = each.value
}
