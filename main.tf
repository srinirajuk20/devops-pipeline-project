resource "aws_instance" "jenkins_terraform" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id = aws_subnet.jenkins_subnet.id
  # Use vpc_security_group_ids for instances in a VPC
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "JenkinsTerraform"
  }
}

resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "JenkinsVPC"
  }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id            = aws_vpc.jenkins_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "JenkinsSubnet"
  }
}

resource "aws_security_group" "jenkins_sg" {
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.jenkins_vpc.id
  name       = "JenkinsSG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}  

resource "aws_internet_gateway" "jenkins_igw" {
    vpc_id = aws_vpc.jenkins_vpc.id
    
    tags = {
        Name = "JenkinsIGW"
    }

}

resource "aws_route_table" "jenkins_route_table" {
    vpc_id = aws_vpc.jenkins_vpc.id
    
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.jenkins_igw.id
    }
}

resource "aws_route_table_association" "jenkins_route_table_association" {
    subnet_id = aws_subnet.jenkins_subnet.id
    route_table_id = aws_route_table.jenkins_route_table.id
}

