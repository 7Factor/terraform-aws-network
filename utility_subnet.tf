resource "aws_subnet" "utility_subnet" {
  vpc_id                  = aws_vpc.primary_vpc.id
  cidr_block              = var.utility_subnet_cidr
  map_public_ip_on_launch = var.enable_utility_public_ips
  depends_on              = [aws_vpc_ipv4_cidr_block_association.utility_subnet_cidr]

  tags = {
    Name = "Utility Subnet"
  }
}

# Let's also add the utility subnet to the public routes.
resource "aws_route_table_association" "utility_subnet_routes" {
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = aws_subnet.utility_subnet.id
  depends_on     = [aws_route_table.public_route_table]
}