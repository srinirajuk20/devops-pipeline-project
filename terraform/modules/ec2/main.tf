resource "aws_instance" "flask_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install docker.io -y
              systemctl start docker
              systemctl enable docker

              docker pull rajugsk20/devops-flask-app:latest || true
              docker run -d -p 5000:5000 --name flask-app rajugsk20/devops-flask-app:latest || true
              EOF

  tags = {
    Name        = "flask-ec2-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}
