# Build out the route tables before we associate routes with them.
resource "aws_route_table" "public_route_table" {
  vpc_id     = aws_vpc.primary_vpc.id
  depends_on = ["aws_internet_gateway.igw"]

  tags = {
    Name = "Public routing table"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id     = aws_vpc.primary_vpc.id
  depends_on = ["aws_nat_gateway.nat_gw"]

  tags = {
    Name = "Private routing table"
  }
}

# Add an iGW to the public route table
resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Add the NAT gateway to the private route table
resource "aws_route" "private_subnets_to_nat" {
  route_table_id         = aws_route_table.private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Associate all public subnets with the public routing table. There's a
# hideous hack here because terraform cannot count computed lists. We
# instead use the total number of public subnets defined in vars.
resource "aws_route_table_association" "public_subnet_routes" {
  count          = length(var.public_private_subnet_pairs)
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  depends_on     = ["aws_route_table.public_route_table"]
}

# Let's also add the utility subnet to the public routes.
resource "aws_route_table_association" "utility_subnet_routes" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.utility_subnet.id
  depends_on     = ["aws_route_table.public_route_table"]
}

# Set main route table to private
resource "aws_main_route_table_association" "main_route" {
  vpc_id         = aws_vpc.primary_vpc.id
  route_table_id = aws_route_table.private_route_table.id
}
