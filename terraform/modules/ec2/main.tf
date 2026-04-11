resource "aws_instance" "flask_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  tags = {
    Name        = "flask-ec2-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}
