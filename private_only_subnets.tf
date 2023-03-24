# Create private only subnets.
resource "aws_subnet" "addl_private_subnets" {
  vpc_id            = aws_vpc.primary_vpc.id
  for_each             = var.addl_private_subnets
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.utility_subnet_cidr,
    aws_vpc_ipv4_cidr_block_association.addl_subnet_cidrs,
  ]

  tags = {
    Name = "Private Only Subnet (${each.value.az})"
    Tier = "Private Only Subnets"
  }
}