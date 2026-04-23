output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}

output "asg_name" {
  value = aws_autoscaling_group.app_asg.name
}

output "launch_template_id" {
  value = aws_launch_template.app_lt.id
}

output "db_endpoint" {
  value = aws_db_instance.app_db.address
}

output "db_name" {
  value = aws_db_instance.app_db.db_name
}

output "cloudwatch_alarm_name" {
  value = aws_cloudwatch_metric_alarm.high_cpu_asg.alarm_name
}

output "bucket_name" {
  value = module.s3.bucket_name
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}
