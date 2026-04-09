data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "security_group" {
  source      = "./modules/security-group"
  environment = var.environment
}

module "ec2" {
  source            = "./modules/ec2"
  ami_id            = data.aws_ami.ubuntu.id
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
