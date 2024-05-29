
provider "aws" {
  region = "ap-south-1"
}

// Create EC2 Instance

resource "aws_instance" "WebSVR" {
  ami = "ami-0f58b397bc5c1f2e8"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.pubsubnet1.id

  tags = {
    Name = "WebSVR"
  }
}

// Create VPC

resource "aws_vpc" "WebSVR-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
   
  tags = {
          Name = "WebSVR-VPC"  
}
}

// Create Subnet

  resource "aws_subnet" "pubsubnet1" {
    vpc_id = aws_vpc.WebSVR-vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true

    tags = {
      Name = "pubsubnet1"

}
}

// Creat Private Subnet

resource "aws_subnet" "pvtsubnet1" {
  vpc_id = aws_vpc.WebSVR-vpc.id
  cidr_block = "10.0.2.0/24"
  
  tags = {
    Name = "pvtsubnet1"
  }
}

// Create Internet Gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.WebSVR-vpc.id

  tags = {
    name = "igw"
  }
}

// Create Public Route Table

resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.WebSVR-vpc.id

  route  {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
    tags = {
      Name = "pub-rt"
    }

}

// Create Private Route Table

resource "aws_route_table" "pvt-rt" {
  vpc_id = aws_vpc.WebSVR-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "pvt-rt"
  }

}

  resource "aws_eip" "EIP" {
  instance = "aws_instance.WebSVR"
   
   domain = "standard" // vpc = true is deprecated
  
   tags = {
    Name = "EIP"
  }
  
}
// Create Nat Gateway to connect to Internet

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.EIP.id
  subnet_id = aws_subnet.pubsubnet1.id

  tags = {
    Name = "nat-gw"
  }
  
}

// ASscoiate Public Route Table to subnets

resource "aws_route_table_association" "public-association" {
  subnet_id = aws_subnet.pubsubnet1.id
  route_table_id = "aws_route_table.pub-rt"
  
} 

// Asscoiate Private Route Table to subnets

resource "aws_route_table_association" "Private_association" {
  subnet_id = aws_subnet.pvtsubnet1.id
  route_table_id = "aws_route_table.pvt-rt"
  
}

// Create Security Group

resource "aws_security_group" "WebSVR-sg" {
  name        = "WebSVR-sg"
  description = "Allow inbound traffic on port 22"
  vpc_id      = aws_vpc.WebSVR-vpc.id
  egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp" // Access ssh from any IP address 
        cidr_blocks = ["0.0.0.0/0"]       
  }
    ingress {

      // Open any other port if required for.e.g
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"] // Access from any source
    }
    
    tags = {
      name = "WebSVR-sg"
    }
}     

