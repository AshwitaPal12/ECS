resource "aws_autoscaling_group" "asg" {
  name                 = "ecs-asg"
  desired_capacity     = 2
  min_size             = 2
  max_size             = 3
  termination_policies = ["OldestInstance"]
  availability_zones   = data.aws_availability_zones.zones.names
  target_group_arns     = [aws_lb_target_group.target.arn]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "template" {
  name = "ecs-launch-template"
  instance_type = "t4g.micro"
  image_id = "ami-02bc45136ff0b128e"
  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 30
      volume_type = "gp3"
      delete_on_termination = true
    }
  }

  vpc_security_group_ids = [aws_security_group.ec2_secgrp.id]

  credit_specification {
    cpu_credits = "standard"
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.profile.arn
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance"
    }
  }

   user_data = base64encode(data.template_file.userdata.rendered)

}

resource "aws_iam_instance_profile" "profile" {
  name = "ecs-profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name               = "ecs-role"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}
resource "aws_security_group" "ec2_secgrp" {
  name        = "ecs-instance-secgrp"
  description = "ecs-instance secgrp"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-ec2-secgrp"
  }

}
