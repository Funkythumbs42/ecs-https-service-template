output "service_url" {
  value = "https://${var.domain_name}"
}

output "ecr_repository_url" {
  value = local.ecr_repo_url
}

output "cluster_name" {
  value = data.aws_ecs_cluster.this.cluster_name
}

output "service_name" {
  value = aws_ecs_service.this.name
}

output "task_definition_arn" {
  value = aws_ecs_task_definition.this.arn
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "ssm_prefix" {
  value = local.ssm_prefix
}

output "image" {
  value = local.image
}
