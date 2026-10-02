# ------------------------------------------------------------------------------
# Per-service ALB.
#
# OPTIONAL ALTERNATIVE - shared ALB:
# If the platform provides a shared ALB with an HTTPS listener, delete the
# aws_lb, aws_lb_listener and alb security group resources below and instead:
#
#   data "aws_lb_listener" "shared_https" {
#     arn = var.shared_https_listener_arn
#   }
#
#   resource "aws_lb_listener_rule" "this" {
#     listener_arn = data.aws_lb_listener.shared_https.arn
#     priority     = var.listener_rule_priority   # must be unique on the listener
#     action {
#       type             = "forward"
#       target_group_arn = aws_lb_target_group.this.arn
#     }
#     condition {
#       host_header { values = [var.domain_name] }
#     }
#   }
#
#   resource "aws_lb_listener_certificate" "this" {   # SNI cert on the shared listener
#     listener_arn    = data.aws_lb_listener.shared_https.arn
#     certificate_arn = aws_acm_certificate_validation.this.certificate_arn
#   }
#
# ...and point the Route 53 alias at the shared ALB, and allow the shared ALB's
# security group into the service security group on container_port.
# ------------------------------------------------------------------------------

resource "aws_lb" "this" {
  name                       = substr(local.name, 0, 32)
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.alb.id]
  subnets                    = data.aws_subnets.public.ids
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "this" {
  name                 = substr(local.name, 0, 32)
  port                 = var.container_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = data.aws_vpc.this.id
  deregistration_delay = 30

  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.this.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
