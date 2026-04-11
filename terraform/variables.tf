variable "aws_region" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "environment" {
  type = string
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  description = "Custom AMI ID for EC2 instance"
  type        = string
}
