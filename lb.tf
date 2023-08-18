resource "aws_lb" "lb" {
  name               = "ecs-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = data.aws_subnets.subnets.ids
}

resource "aws_security_group" "lb_sg" {
  name        = "ecs-lb-sg"
  description = "Load balancer security firewall"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_listener" "http_listner" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

resource "aws_lb_target_group" "target" {
  name     = "nginx-ecs"
  protocol = "HTTP"
  port     = 80
  vpc_id   = aws_default_vpc.default.id

  health_check {
    path = "/"
    protocol            = "HTTP"
    interval            = 10
    unhealthy_threshold = 3
    matcher             = "200"
  }
}
