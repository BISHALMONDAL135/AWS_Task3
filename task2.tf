provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAW75GPH5THPZNPKGV"
  secret_key = "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"
}
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_hostnames=true

  tags = {
    Name = "my_vpc"
  
 }
}
resource "aws_subnet" "vpc_private" {
     depends_on =[
      aws_vpc.myVPC
     ]
    vpc_id = aws_vpc.myVPC.id


    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = false

    tags = {
        Name = "my_Private_Subnet"
    }
}
resource "aws_subnet" "vpc_public" {
depends_on =[
      aws_subnet.vpc_private
     ]
    
    vpc_id = aws_vpc.myVPC.id


    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-south-1b"
    map_public_ip_on_launch = true
    
    tags = {
        Name = "my_Public_Subnet"
    }
  

}
resource "aws_internet_gateway" "my_gateway" {
  depends_on =[
      aws_subnet.vpc_private
     ]
  vpc_id = aws_vpc.myVPC.id


  tags = {
    Name = "my_vpcgateway"
  }

}
resource "aws_route_table" "my_routetable" {
    depends_on =[
      aws_internet_gateway.my_gateway
     ]
  vpc_id = aws_vpc.myVPC.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gateway.id
  }


  tags = {
    Name = "my_RoutingTable"
  }

}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.vpc_public.id
  route_table_id = aws_route_table.my_routetable.id
}

resource "aws_key_pair" "mykey2" {
  key_name   = "mykey2"
  public_key = file("mykey2.pub")
}

resource "aws_security_group" "securitygrp1" {
depends_on =[
      aws_subnet.vpc_public
     ]


 name = " Public_Security_Group"
 description = "Security Group for Wordpress"
 vpc_id = aws_vpc.myVPC.id
 
 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
 tags ={
   Name ="public_security_group"
 }
}
resource "aws_instance" "wordpress" {
depends_on =[
      aws_instance.mysql
     ]
 ami     =  "ami-049cbce295a54b26b"
 instance_type = "t2.micro"
  key_name = aws_key_pair.mykey2.key_name
 vpc_security_group_ids = [ aws_security_group.securitygrp1.id]
 subnet_id      = aws_subnet.vpc_public.id


 tags = {
  Name = "wordpress"
 }

}
resource "aws_security_group" "securitygrp2" {
  
depends_on =[
      aws_subnet.vpc_private
     ]


 name = " Private Security Group"
 description = "Security Group for MySQL"
 vpc_id = aws_vpc.myVPC.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
 tags ={
   Name ="private_security_group"
}
}
resource "aws_instance" "mysql" {
depends_on =[
      aws_security_group.securitygrp2
     ]
 ami     =  "ami-08706cb5f68222d09"
 instance_type = "t2.micro"
  key_name = aws_key_pair.mykey2.key_name
 vpc_security_group_ids = [ aws_security_group.securitygrp2.id]
 subnet_id      = aws_subnet.vpc_private.id
 tags = {
  Name = "Mysql"
 }
}
