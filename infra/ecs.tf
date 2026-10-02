resource "aws_ecs_task_definition" "this" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name      = local.container_name
    image     = local.image
    essential = true

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    environment = [
      { name = "ASPNETCORE_ENVIRONMENT", value = var.environment },
    ]


    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "app"
      }
    }
  }])
}

resource "aws_ecs_service" "this" {
  name            = local.name
  cluster         = data.aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.this.arn
  launch_type     = "FARGATE"

  # Bootstrap: with no image yet (image_digest empty) the service is created
  # with zero tasks. The first app deploy scales the service up.
  desired_count = local.bootstrapping ? 0 : var.desired_count

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = data.aws_subnets.private.ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.https]
}
