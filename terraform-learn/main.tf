provider "aws" {
    region = "ca-central-1"
    # access_key = "read from aws config"
    # secret_key = "read from aws config"
}

variable "subnet_cidr_block" {
  description = "subnet cidr block"
}

resource "aws_vpc" "development-vpc" {
   cidr_block = "10.0.0.0/16"
   tags = {
        Name: "development"
   }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = "ca-central-1a"
    tags = {
        Name: "subnet-1-dev"
        vpc-env: "dev"
    }
}

// Query existing resources / components
data "aws_vpc" "existing_vpc" {
    default = true
}

resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing_vpc.id
    cidr_block = "172.31.48.0/20"
    availability_zone = "ca-central-1a"
    tags = {
        Name: "subnet-1-default"
    }
}


//Output enables specify what values we want to output, after terraform completes 
// applying configurations for one of our resources
output "dev-vpc-id" {
   value = aws_vpc.development-vpc.id
}

output "dev-subnet-id" {
   value = aws_subnet.dev-subnet-1.id
}