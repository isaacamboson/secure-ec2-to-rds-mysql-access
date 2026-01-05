/*
Purpose: Define the primary VPC, public and private subnets, Internet Gateway
         and NAT Gateways plus route tables. Keep networking isolated so
         sensitive resources (databases, internal services) live in private
         subnets without direct inbound internet access.

Security notes:
 - Public subnets should only contain resources that require inbound internet
   access (e.g., NAT gateways).
 - Private subnets host application and database resources and route outbound
   traffic through NAT Gateways to limit direct exposure.
 - Keep route table and subnet CIDRs aligned with your security/AZ strategy.
*/

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project}-vpc"
  }
}

#creating public subnets
resource "aws_subnet" "pub_subnets" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${var.project}-public-subnet-${count.index + 1}"
  }
}

# Create private subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.project}-private-subnet-${count.index + 1}"
  }
}

#creating IGW for the VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project}-igw"
  }
}

#associating the main vpc route table with the IGW
resource "aws_route" "pub_custom_route_table" {
  route_table_id         = aws_vpc.main.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

#creating EIPs for NAT Gateways
resource "aws_eip" "eip_aws_nat_gtwy" {
  count      = length(var.azs)
  depends_on = [aws_internet_gateway.igw]
}

# Associating EIPs with NAT Gateways
resource "aws_nat_gateway" "nat_gateway_pub" {
  count         = length(var.azs)
  allocation_id = element(aws_eip.eip_aws_nat_gtwy.*.id, count.index)
  subnet_id     = element(aws_subnet.pub_subnets.*.id, count.index)
  depends_on    = [aws_eip.eip_aws_nat_gtwy, aws_subnet.pub_subnets]

  tags = {
    Name = "${var.project}-nat-gateway-${count.index + 1}"
  }
}

#creating custom route tables for the private subnets
resource "aws_route_table" "private_custom_route_table" {
  count  = length(var.azs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = element(aws_nat_gateway.nat_gateway_pub.*.id, count.index)
  }

  tags = {
    Name = "${var.project}-route-table-${count.index + 1}"
  }
}

# associating route tables with the private subnets
resource "aws_route_table_association" "rt_association_private_subnets" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private_custom_route_table.*.id, count.index)
}
    