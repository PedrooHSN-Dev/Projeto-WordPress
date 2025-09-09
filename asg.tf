data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "wordpress" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.wordpress.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress_instance_profile.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name       = var.tag_name
      CostCenter = var.tag_costcenter
      Project    = var.tag_project
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name       = var.tag_name
      CostCenter = var.tag_costcenter
      Project    = var.tag_project
    }
  }
 
  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    db_host      = aws_db_instance.wordpress.address
    db_name      = aws_db_instance.wordpress.db_name
    db_user      = var.db_username
    db_password  = var.db_password
    efs_dns_name = aws_efs_file_system.wordpress.dns_name
  }))
}

resource "aws_autoscaling_group" "wordpress" {
  name                = "${var.project_name}-asg"
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = aws_subnet.private[*].id

  launch_template {
    id      = aws_launch_template.wordpress.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.wordpress.arn]

  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "${var.project_name}-cpu-scaling-policy"
  autoscaling_group_name = aws_autoscaling_group.wordpress.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}