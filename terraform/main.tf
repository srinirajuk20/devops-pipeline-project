
module "ec2" {
  source            = "./modules/ec2"
  ami_id            = var.ami_id
  instance_type     = var.instance_type
  security_group_id = module.security_group.security_group_id
  environment       = var.environment
  key_name          = var.key_name
}

module "s3" {
  source        = "./modules/s3"
  bucket_name   = var.bucket_name
  environment   = var.environment
  create_bucket = var.environment == "prod"
}

module "security_group" {
  source                = "./modules/security-group"
  environment           = var.environment
  alb_security_group_id = aws_security_group.alb_sg.id
}

data "aws_subnets" "default" {
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

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

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg-${var.environment}"
  description = "Allow HTTP to ALB"

  ingress {
    description = "Allow HTTP from internet"
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
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "app-tg-${var.environment}"
  port     = 80
  protocol = "HTTP"
  vpc_id = module.security_group.vpc_id

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

resource "aws_lb_target_group_attachment" "app_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = module.ec2.instance_id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
