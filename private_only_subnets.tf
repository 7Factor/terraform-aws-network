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