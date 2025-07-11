data "aws_autoscaling_group" "rtsp_asg" {
  name = aws_autoscaling_group.this.name
}

data "aws_instances" "rtsp_instances" {
  instance_tags = {
    "aws:autoscaling:groupName" = data.aws_autoscaling_group.rtsp_asg.name
  }
}

output "rtsp_private_ips" {
  value = data.aws_instances.rtsp_instances.private_ips
}
