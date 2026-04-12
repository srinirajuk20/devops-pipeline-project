resource "aws_security_group" "flask_sg" {
  name        = "flask-sg-${var.environment}"
  description = "Allow Flask app traffic"

  ingress {
    description = "Allow Flask HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from Jenkins"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "flask-sg-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}
