output "instance_id" {
  value = aws_instance.flask_server.id
}

output "public_ip" {
  value = aws_instance.flask_server.public_ip
}
