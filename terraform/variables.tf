variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "alb_name" {
  type    = string
  default = "devops-alb"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "image_name" {
  type    = string
  default = "rajugsk20/devops-flask-app"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 2
}

variable "db_name" {
  type    = string
  default = "appdb"
}

variable "db_user" {
  type    = string
  default = "appuser"
}

variable "db_password" {
  type = string
}
