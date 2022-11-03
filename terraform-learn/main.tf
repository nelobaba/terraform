provider "aws" {
    region = "ca-central-1"
}

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}
variable "subnet_cidr_block" {
  description = "subnet cidr block"
}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {
  
}
variable "pulic_key_location" {
  
}

// VPCs
resource "aws_vpc" "myapp-vpc" {
   cidr_block = var.vpc_cidr_block
   tags = {
        Name: "${var.env_prefix}-vpc"
   }
}
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

// Route Table and Internet Gateway
// Think about this as a virtual router inside your VPC

# resource "aws_route_table" "myapp-route-table" {
#   vpc_id = aws_vpc.myapp-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
#   tags = {
#     Name: "${var.env_prefix}-rtb"
#   }
# }

# //Associate subnets to this created VPC so our subnets does not get associated to default VPC

# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }


//we are connecting vpc to internet gateway and we are configuring a new route 
// table above that we're creating in the VPC to route all traffic to and from
//internet using these internet gateway

//Think about this as a virtual modem that connects you to the internet
resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
  tags = {
    Name: "${var.env_prefix}-igw"
  }
}

// incase you decide to use default route table, no need for subnet association
resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
  tags = {
    Name: "${var.env_prefix}-main-rtb"
  }
}

// Configure Firewall Rules to EC2 .. hence we need security group (server firewall)
# resource "aws_security_group" "myapp-sg" {
#   name = "myapp-sg"
#   vpc_id = aws_vpc.myapp-vpc.id

#   //rules for incoming traffic rules
#   ingress {
#     from_port = 22
#     to_port = 22
#     protocol = "tcp"
#     cidr_blocks = [var.my_ip] //my IP
#   }

#   ingress {
#     from_port = 8080
#     to_port = 8080
#     protocol = "tcp"
#     cidr_blocks = ["0.0.0.0/0"] //Any IP
#   }

# // installing resources from the internet
#   egress {
#     from_port = 0
#     to_port = 0
#     protocol = "-1"
#     cidr_blocks = ["0.0.0.0/0"] //Any IP
#     prefix_list_ids = []
#   }

#   tags = {
#     Name: "${var.env_prefix}-sg"
#   }
# }

// Default security group intead of creating another custom security group
resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  //rules for incoming traffic rules
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip] //my IP
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] //Any IP
  }

// installing resources from the internet
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] //Any IP
    prefix_list_ids = []
  }

  tags = {
    Name: "${var.env_prefix}-default--sg"
  }
}


// fetch ami info
# data "aws_ami" "latest-amazon-linux-image" {
#     most_recent = true
#     owners = ["704109570831"]
#     filter {
#       name = "name"
#       values = ["ztna_ubuntu2004"]
#     }
#     filter {
#       name = "virtualization-type"
#       values = ["hvm"]
#     }
# }
data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["704109570831"]
    filter {
      name = "name"
      values = ["ztna_ubuntu2004"]
    }
    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

output "aws_ami" {
  value = data.aws_ami.latest-amazon-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.myapp-server.public_ip
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.pulic_key_location)
}

// Create EC2
resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id// OS image id
  instance_type = var.instance_type

  subnet_id = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids =  [aws_default_security_group.default-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
#   key_name = "server-key-pair"
  key_name = aws_key_pair.ssh-key.key_name

  // run commands on EC2 when the server is initialized
  // you might need to run those manually in ubuntu ami image
#   user_data = <<EOF
#     #!/bin/bash
#     sudo apt-get update
#     sudo snap install  docker
#     sudo snap start docker
#     sudo usermod -aG docker ubuntu
#     sudo docker run -p 8080:80 nginx
#   EOF

  user_data = file("entry-script.sh")

  tags = {
    Name: "${var.env_prefix}-server"
  }
}