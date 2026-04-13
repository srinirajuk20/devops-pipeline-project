variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "AWS EC2 key pair name"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "ami_id" {
  description = "Custom AMI ID for EC2"
  type        = string
}

variable "alb_name" {
  type    = string
  default = "devops-alb"
}
