resource "aws_launch_template" "this" {
  name_prefix   = "${var.name_prefix}-rtsp"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.security_group_id]
    subnet_id                   = var.subnet_ids[0]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {
    REGION = var.region
    RTSP_TRIGGER_SH = file("${path.module}/rtsp_ansible_trigger.sh")
    RTSP_TRIGGER_SERVICE = file("${path.module}/rtsp_ansible_trigger.service")
  }))

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name                = "${var.name_prefix}-rtsp-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  health_check_type = "EC2"
  force_delete      = true

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-rtsp"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "target_tracking" {
  name                      = "target-tracking-policy"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.this.name
  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = 60.0
    disable_scale_in = false
  }
}
