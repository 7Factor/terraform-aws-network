# Create the private subnets for the public/private pairs
resource "aws_subnet" "private_subnets" {
  vpc_id = aws_vpc.primary_vpc.id
  for_each = flatten([
    for az, subnets in var.az_subnet_pairs : [
      for subnet in subnets : {
        az   = az
        cidr = subnet.cidr
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


# Create the EIPs for the NAT gateways first.
resource "aws_eip" "nat_ips" {
  count = length(var.az_subnet_pairs)
  vpc   = true

  tags = {
    Name = "NAT EIP"
  }
}

# NAT gateways
resource "aws_nat_gateway" "nat_gws" {
  for_each = flatten([
    for index, az in keys(var.az_subnet_pairs) : [
      for utility_subnet in aws_subnet.utility_subnets : {
        utility_subnet_id = utility_subnet.id
        index = index
      } if utility_subnet.availability_zone == az
    ]
  ])
  subnet_id     = each.value.id
  allocation_id = aws_eip.nat_ips[each.value.index].id
  depends_on    = [aws_eip.nat_ips]

  tags = {
    Name = "NAT Gateways for private subnets"
  }
}

resource "aws_route_table" "private_route_tables" {
  for_each   = var.az_subnet_pairs
  vpc_id     = aws_vpc.primary_vpc.id
  depends_on = [aws_nat_gateway.nat_gws]

  tags = {
    Name = "Private routing table"
  }
}

# Add the NAT gateways to private route tables
resource "aws_route" "private_subnets_to_nat" {
  for_each               = aws_nat_gateway.nat_gws
  route_table_id         = aws_route_table.private_route_tables[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = each.value.id
}

# Associate each private subnet with route table to the NAT
resource "aws_route_table_association" "private_route_associations" {
  for_each = flatten([
    for index, nat in aws_nat_gateway.nat_gws : [
      for route_table in aws_route.private_subnets_to_nat : {
        subnet_id      = nat.subnet_id
        route_table_id = route_table.id
      } if route_table.nat_gateway_id == nat.id
    ]
  ])
  subnet_id      = each.value.subnet_id
  route_table_id = each.value.route_table_id
}

# Set up a main route table with no routes to protect new subnets by default
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "Main routing table"
  }
}

resource "aws_main_route_table_association" "main_route" {
  vpc_id         = aws_vpc.primary_vpc.id
  route_table_id = aws_route_table.main_route_table.id
}
