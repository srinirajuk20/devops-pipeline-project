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

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 3 
}

variable "image_name" {
  # type    = string
  # default = "rajugsk20/devops-flask-app"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "image_tag" {
  #  type    = string
  #  default = "latest"
}

variable "active_color" {
  type    = string
  default = "blue"
}


variable "blue_desired_capacity" {
  type    = number
  default = 2
}

variable "blue_min_size" {
  type    = number
  default = 2
}

variable "blue_max_size" {
  type    = number
  default = 4
}

variable "green_desired_capacity" {
  type    = number
  default = 2
}

variable "green_min_size" {
  type    = number
  default = 2
}

variable "green_max_size" {
  type    = number
  default = 3
}
