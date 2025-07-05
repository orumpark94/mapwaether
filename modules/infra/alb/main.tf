# ALB 생성 (퍼블릭 서브넷)
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = [var.alb_sg_id]

  tags = { Name = "${var.name}-alb" }
}

# Map API Target Group (port 3000)
resource "aws_lb_target_group" "map" {
  name     = "${var.name}-map-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    port                = "3000"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = { Name = "${var.name}-map-tg" }
}

# ALB Listener (80 포트, 기본 응답 설정)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

# 경로 기반 라우팅: /map → map-api Target Group
resource "aws_lb_listener_rule" "map" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.map.arn
  }

  condition {
    path_pattern {
      values = ["/map", "/map*"]
    }
  }
}
