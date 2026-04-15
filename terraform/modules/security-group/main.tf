resource "aws_security_group" "flask_sg" {
  name        = "flask-sg-${var.environment}"
  description = "Allow Flask app traffic"

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  dynamic "ingress" {
    for_each = var.alb_security_group_id != null ? [1] : []
    content {
      description     = "Allow HTTP from ALB only"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      security_groups = [var.alb_security_group_id]
    }
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
