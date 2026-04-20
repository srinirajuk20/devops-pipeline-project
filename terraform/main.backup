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
# ALB Security Group (Public)
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
# EC2 Security Group (Module)
########################################

module "security_group" {
  source                = "./modules/security-group"
  environment           = var.environment
  alb_security_group_id = aws_security_group.alb_sg.id
#  ssh_allowed_cidr      = var.ssh_allowed_cidr
}

########################################
# S3 Module (Optional)
########################################

module "s3" {
  source        = "./modules/s3"
  bucket_name   = var.bucket_name
  environment   = var.environment
  create_bucket = var.environment == "prod"
}

########################################
# Application Load Balancer
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
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
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
# Launch Template (Custom AMI)
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

              apt update -y
              apt install -y nginx

              systemctl enable docker
              systemctl start docker

              sudo systemctl stop nginx || true
              sudo systemctl disable nginx || true
              
              docker stop flask-app || true
              docker rm flask-app || true
              
              docker pull ${var.image_name}:${var.image_tag}

              docker run -d \
	             --name flask-app \
	             --restart unless-stopped \
	              -p 80:5000 \
	               ${var.image_name}:${var.image_tag}

              tee /etc/nginx/sites-available/default > /dev/null <<'EONGINX'
              server {
                  listen 80;
                  server_name _;

                  location / {
                      proxy_pass http://127.0.0.1:5000;
                      proxy_set_header Host \$host;
                      proxy_set_header X-Real-IP \$remote_addr;
                      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                      proxy_set_header X-Forwarded-Proto \$scheme;
                  }
              }
              EONGINX

              nginx -t
              systemctl restart nginx
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "asg-app-${var.environment}"
      Environment = var.environment
      Project     = "devops-pipeline-project"
    }
  }
}

########################################
# Auto Scaling Group
########################################

resource "aws_autoscaling_group" "app_asg" {
  name                = "app-asg-${var.environment}"
  desired_capacity    = var.desired_capacity
  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-app-${var.environment}"
    propagate_at_launch = true
  }

instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }
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

resource "aws_cloudwatch_metric_alarm" "high_cpu_asg" {
  alarm_name          = "high-cpu-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Alarm when EC2 CPU exceeds 70%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }
}

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

