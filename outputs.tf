output "ec2_instance" {
    value = aws_instance.jenkins_terraform.public_ip  
}

output "ec2_instance_dns" {
    value = aws_instance.jenkins_terraform.public_dns
  
}