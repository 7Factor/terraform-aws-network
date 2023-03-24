# Create the private subnets for the public/private pairs
resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.primary_vpc.id
  for_each = flatten([
    for az in var.availability_zones : [
      for pair in(az.public_private_subnet_pairs) : {
        az   = az
        cidr = pair.cidr
      }
    ]
  ])
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.utility_subnet_cidr,
    aws_vpc_ipv4_cidr_block_association.addl_subnet_cidrs,
  ]

  tags = {
    Name = "Private Subnet (${each.value.az})"
    Tier = "Private Subnets"
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

resource "aws_route_table" "private_route_table" {
  vpc_id     = aws_vpc.primary_vpc.id
  depends_on = [aws_nat_gateway.nat_gw]

  tags = {
    Name = "Private routing table"
  }
}

# Add the NAT gateway to the private route table
resource "aws_route" "private_subnets_to_nat" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Set main route table to private
resource "aws_main_route_table_association" "main_route" {
  vpc_id         = aws_vpc.primary_vpc.id
  route_table_id = aws_route_table.private_route_table.id
}
