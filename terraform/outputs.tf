output "instance_id" {
  value = module.ec2.instance_id
}

output "instance_public_ip" {
  value = module.ec2.public_ip
}

output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}
