variable "service_name" {
  description = "Short, DNS-safe name of the service. Used for resource names and SSM paths."
  type        = string
  default     = "my-service"
}

variable "environment" {
  description = "Environment name (dev, stage, prod)."
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-1"
}

# --- Existing platform resources (looked up, not created) ---------------------

variable "cluster_name" {
  description = "Name of the existing ECS cluster."
  type        = string
  default     = "main-ecs-cluster"
}

variable "vpc_id" {
  description = "ID of the existing VPC. Leave empty to look the VPC up by vpc_tag_name."
  type        = string
  default     = ""
}

variable "vpc_tag_name" {
  description = "Value of the Name tag of the existing VPC (used when vpc_id is empty)."
  type        = string
  default     = "main"
}

variable "public_subnet_tags" {
  description = "Tags identifying the existing public subnets (for the ALB)."
  type        = map(string)
  default     = { Tier = "public" }
}

variable "private_subnet_tags" {
  description = "Tags identifying the existing private subnets (for the ECS tasks)."
  type        = map(string)
  default     = { Tier = "private" }
}

# --- DNS / TLS -----------------------------------------------------------------

variable "hosted_zone_name" {
  description = "Existing public Route 53 hosted zone, e.g. example.com."
  type        = string
}

variable "domain_name" {
  description = "FQDN for the service, e.g. my-service.dev.example.com. Must sit inside hosted_zone_name."
  type        = string
}

# --- Container / task ------------------------------------------------------------

variable "create_ecr_repository" {
  description = "Create the ECR repository in this environment. Exactly one environment (normally dev) should own the repo; the others look the repo up so the same digest can be promoted."
  type        = bool
  default     = false
}

variable "image_digest" {
  description = "Image digest (sha256:...) to run. Normally injected by scripts/tf-plan.sh from SSM so an infra apply never rolls back the image. Empty = bootstrap (service created with 0 tasks)."
  type        = string
  default     = ""

  validation {
    condition     = var.image_digest == "" || can(regex("^sha256:[a-f0-9]{64}$", var.image_digest))
    error_message = "image_digest must be empty or of the form sha256:<64 hex chars>."
  }
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units (256, 512, 1024, ...)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate task memory in MiB (must be valid for the chosen cpu)."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of tasks to run once an image has been deployed."
  type        = number
  default     = 1
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target group health check."
  type        = string
  default     = "/health"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}
