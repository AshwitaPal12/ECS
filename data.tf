data "aws_iam_policy_document" "ecs_task_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id == null ? aws_default_vpc.default.id : var.vpc_id]
  }
}

data "aws_vpc" "vpc" {
  count = var.vpc_id == null ? 0 : 1
  id    = var.vpc_id
}

data "aws_availability_zones" "zones" {
  state = "available"
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

data "template_file" "userdata" {
  template = <<-EOT
  #! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=${var.cluster_name}" >> /etc/ecs/ecs.config
EOT
}
