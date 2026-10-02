resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "ALB for ${local.name}: HTTP/HTTPS from the internet"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP (redirected to HTTPS)"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_service" {
  security_group_id            = aws_security_group.alb.id
  description                  = "To service tasks"
  referenced_security_group_id = aws_security_group.service.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
}

resource "aws_security_group" "service" {
  name        = "${local.name}-service"
  description = "ECS tasks for ${local.name}: only from the ALB"
  vpc_id      = data.aws_vpc.this.id
}

resource "aws_vpc_security_group_ingress_rule" "service_from_alb" {
  security_group_id            = aws_security_group.service.id
  description                  = "From ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.container_port
  to_port                      = var.container_port
}

# Tasks need outbound access (ECR, CloudWatch Logs, dependencies) via NAT or VPC endpoints.
resource "aws_vpc_security_group_egress_rule" "service_all" {
  security_group_id = aws_security_group.service.id
  description       = "Outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
