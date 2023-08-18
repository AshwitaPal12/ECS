resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
}

resource "aws_ecs_cluster_capacity_providers" "ecs-cluster" {
   
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
    ]

  default_capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 1
  }

  cluster_name = aws_ecs_cluster.cluster.name
}

resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.cluster.name
  launch_type     = var.launch_type.type
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1

  load_balancer {
    container_name   = "nginx"
    container_port   = 80
    target_group_arn = aws_lb_target_group.target.arn
  }

  dynamic "network_configuration" {
    for_each = var.network_mode == "awsvpc" ? [1] : []
    content {
      subnets          = data.aws_subnets.subnets.ids
      security_groups  = [aws_security_group.secgrp.id]
    }
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.task_family
  network_mode             = var.network_mode
  requires_compatibilities = [var.launch_type.type]
  execution_role_arn       = aws_iam_role.task_role.arn

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:1.18-alpine"
      cpu       = 10
      memory    = 256
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  cpu = var.launch_type.cpu
  memory = var.launch_type.memory

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
}


resource "aws_iam_role" "task_role" {
  name               = "ecs-task-${var.task_family}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_policy.json

  inline_policy {
    name = "ecs-task-permissions"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ecr:*",
            "logs:*",
            "ssm:*",
            ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}

resource "aws_default_vpc" "default" {
 
}

resource "aws_security_group" "secgrp" {
  name        = "${var.service_name}-ecs-secgrp"
  description = "${var.service_name} ecs security group"
  vpc_id      = var.vpc_id == null ? aws_default_vpc.default.id : var.vpc_id

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
     security_groups = [aws_security_group.lb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.service_name}-ecs-secgrp"
  }
}