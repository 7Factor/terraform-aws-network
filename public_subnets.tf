# Create the public subnets for the public/private pairs
resource "aws_subnet" "public_subnets" {
  vpc_id = aws_vpc.primary_vpc.id
  for_each = flatten([
    for az in var.availability_zones : [
      for pair in(az.public_private_subnet_pairs) : {
        az   = az
        cidr = pair.public_cidr
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
    Name = "Public Subnet (${each.value.az})"
    Tier = "Public Subnets"
  }
}

# Create primary IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "IGW for public subnets"
  }
}

# Build out the route tables before we associate routes with them.
resource "aws_route_table" "public_route_table" {
  vpc_id     = aws_vpc.primary_vpc.id
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "Public routing table"
  }
}

# Add an iGW to the public route table
resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate all public subnets with the public routing table. There's a
# hideous hack here because terraform cannot count computed lists. We
# instead use the total number of public subnets defined in vars.
resource "aws_route_table_association" "public_subnet_routes" {
  for_each       = aws_subnet.public_subnets
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = each.value.id
  depends_on     = [aws_route_table.public_route_table]
}