variable "ami_id" {
  description = "The ID of the AMI to use for the instance"
  type        = string  
  
}

variable "instance_type" {
  description = "The type of instance to launch"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair to use for the instance"
  type        = string
}



