########################################
# Data Sources
########################################

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

########################################
# ALB Security Group
########################################

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.environment}"
  description = "Allow HTTP from internet"

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name        = "alb-sg-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}

########################################
# EC2 Security Group
########################################

module "security_group" {
  source                = "./modules/security-group"
  environment           = var.environment
  alb_security_group_id = aws_security_group.alb_sg.id
}

########################################
# Optional S3 Module
########################################

module "s3" {
  source        = "./modules/s3"
  bucket_name   = var.bucket_name
  environment   = var.environment
  create_bucket = var.environment == "prod"
}

########################################
# Database Security Group
########################################

resource "aws_security_group" "db_sg" {
  name        = "db-sg-${var.environment}"
  description = "Allow PostgreSQL from app instances"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.security_group.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "db-sg-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}

########################################
# DB Subnet Group
########################################

resource "aws_db_subnet_group" "db_subnet" {
  name       = "db-subnet-${var.environment}"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name        = "db-subnet-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}

########################################
# RDS PostgreSQL
########################################

resource "aws_db_instance" "app_db" {
  identifier = "app-db-${var.environment}"

  engine         = "postgres"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.db_name
  username = var.db_user
  password = var.db_password

  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  multi_az               = false
  backup_retention_period = 0

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.name

  tags = {
    Name        = "app-db-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}

########################################
# ALB
########################################

resource "aws_lb" "app_alb" {
  name               = "${var.alb_name}-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name        = "${var.alb_name}-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}

########################################
# Target Group
########################################

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.security_group.vpc_id

  health_check {
  enabled             = true
  path                = "/health"
  matcher             = "200"
  interval            = 30
  timeout             = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

  tags = {
    Name        = "app-tg-${var.environment}"
    Environment = var.environment
    Project     = "devops-pipeline-project"
  }
}

########################################
# Listener
########################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

########################################
# IAM for SSM
########################################

resource "aws_iam_role" "ec2_ssm_role" {
  name = "ec2-ssm-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2-profile-${var.environment}"
  role = aws_iam_role.ec2_ssm_role.name
}

########################################
# Launch Template
########################################

resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt-${var.environment}-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [module.security_group.security_group_id]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -euxo pipefail

              systemctl enable docker
              systemctl start docker

              docker stop flask-app || true
              docker rm flask-app || true

              docker pull ${var.image_name}:${var.image_tag}

              docker run -d \
                --name flask-app \
                --restart unless-stopped \
                -p 80:8000 \
                -e DB_HOST=${aws_db_instance.app_db.address} \
                -e DB_NAME=${var.db_name} \
                -e DB_USER=${var.db_user} \
                -e DB_PASSWORD=${var.db_password} \
                ${var.image_name}:${var.image_tag}
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "app-instance-${var.environment}"
      Environment = var.environment
      Project     = "devops-pipeline-project"
    }
  
}

}

########################################
# Auto Scaling Group
########################################

resource "aws_autoscaling_group" "app_asg" {
  name                      = "app-asg-${var.environment}"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  vpc_zone_identifier       = data.aws_subnets.default.ids
  target_group_arns         = [aws_lb_target_group.app_tg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 100
      instance_warmup        = 180
      auto_rollback          = true
      skip_matching          = true
    }

  }

  tag {
    key                 = "Name"
    value               = "app-asg-${var.environment}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "devops-pipeline-project"
    propagate_at_launch = true
  }
}

########################################
# CloudWatch Alarm
########################################

resource "aws_cloudwatch_metric_alarm" "high_cpu_asg" {
  alarm_name          = "high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when app ASG CPU exceeds 70%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}
