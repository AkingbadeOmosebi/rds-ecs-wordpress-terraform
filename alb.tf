# -------- ALB --------
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false # false = internet-facing
  load_balancer_type = "application"

  security_groups = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id
  ]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# -------- ALB Target Group --------
# This is like the guest list — who can receive traffic from the ALB
resource "aws_lb_target_group" "main" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  target_type = "ip"


  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# -------- ALB Listener --------
# This listens on port 80 and forwards traffic to our target group (ECS tasks)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}
