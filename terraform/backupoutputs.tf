output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "blue_asg_name" {
  value = aws_autoscaling_group.blue.name
}

output "green_asg_name" {
  value = aws_autoscaling_group.green.name
}

output "launch_template_id" {
  value = aws_launch_template.app_lt.id
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "high_cpu_blue_alarm_name" {
  value = aws_cloudwatch_metric_alarm.high_cpu_blue.alarm_name
}

output "high_cpu_green_alarm_name" {
  value = aws_cloudwatch_metric_alarm.high_cpu_green.alarm_name
}

output "bucket_name" {
  value = module.s3.bucket_name
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

output "db_endpoint" {
  value = aws_db_instance.app_db.address
}
