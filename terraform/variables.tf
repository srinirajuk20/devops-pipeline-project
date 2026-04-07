variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "bucket_name" {
  description = "Unique S3 bucket name"
  type        = string
}

variable "instance_type" {
  default = "t3.micro"
}
