output "security_group_id" {
  value = aws_security_group.flask_sg.id
}

output "vpc_id" {
  value = aws_security_group.flask_sg.vpc_id
}
