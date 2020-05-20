terraform {
  required_version = ">=0.12.3"
}

provider aws {
  version = "~> 2.62"
}

provider template {
  version = "~> 2.1"
}

resource "aws_vpc" "primary_vpc" {
  cidr_block = var.vpc_primary_cidr

  tags = {
    Name = "Primary VPC"
  }
}

resource "aws_vpc_ipv4_cidr_block_association" "addl_subnet_cidrs" {
  count      = length(var.vpc_addl_address_space)
  cidr_block = var.vpc_addl_address_space[count.index]
  vpc_id     = aws_vpc.primary_vpc.id
}

resource "aws_vpc_ipv4_cidr_block_association" "utility_subnet_cidr" {
  cidr_block = var.utility_subnet_cidr
  vpc_id     = aws_vpc.primary_vpc.id
}

resource "aws_subnet" "utility_subnet" {
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.utility_subnet_cidr
  map_public_ip_on_launch = var.enable_utility_public_ips
  depends_on              = [aws_vpc_ipv4_cidr_block_association.utility_subnet_cidr]

  tags = {
    Name = "Utility Subnet"
  }
}

# Create the private subnets for the public/private pairs
resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.primary_vpc.id
  count             = length(var.public_private_subnet_pairs)
  cidr_block        = lookup(var.public_private_subnet_pairs[count.index], "cidr")
  availability_zone = lookup(var.public_private_subnet_pairs[count.index], "az")

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.utility_subnet_cidr,
    aws_vpc_ipv4_cidr_block_association.addl_subnet_cidrs,
  ]

  tags = {
    Name = "Private Subnet (${lookup(var.public_private_subnet_pairs[count.index], "az")})"
    Tier = "Private Subnets"
  }
}

# Create the public subnets for the public/private pairs
resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.primary_vpc.id
  count             = length(var.public_private_subnet_pairs)
  cidr_block        = lookup(var.public_private_subnet_pairs[count.index], "public_cidr")
  availability_zone = lookup(var.public_private_subnet_pairs[count.index], "az")

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.utility_subnet_cidr,
    aws_vpc_ipv4_cidr_block_association.addl_subnet_cidrs,
  ]

  tags = {
    Name = "Public Subnet (${lookup(var.public_private_subnet_pairs[count.index], "az")})"
    Tier = "Public Subnets"
  }
}

# Create private only subnets.
resource "aws_subnet" "addl_private_subnets" {
  vpc_id            = aws_vpc.primary_vpc.id
  count             = length(var.addl_private_subnets)
  cidr_block        = lookup(var.addl_private_subnets[count.index], "cidr")
  availability_zone = lookup(var.addl_private_subnets[count.index], "az")

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.utility_subnet_cidr,
    aws_vpc_ipv4_cidr_block_association.addl_subnet_cidrs,
  ]

  tags = {
    Name = "Private Only Subnet (${lookup(var.addl_private_subnets[count.index], "az")})"
    Tier = "Private Only Subnets"
  }
}

# Create primary IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "IGW for public subnets"
  }
}

# Create the EIP for the nat gateway first.
resource "aws_eip" "nat_ip" {
  vpc = true

  tags = {
    Name = "NAT EIP"
  }
}

# NAT gateway
resource "aws_nat_gateway" "nat_gw" {
  subnet_id     = aws_subnet.utility_subnet.id
  allocation_id = aws_eip.nat_ip.id
  depends_on    = [aws_eip.nat_ip]

  tags = {
    Name = "NAT Gateway for private subnets"
  }
}
