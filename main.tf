terraform {
  required_version = ">=0.12.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
}

resource "aws_vpc" "primary_vpc" {
  cidr_block = var.vpc_primary_cidr

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = {
    Name = var.vpc_name
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
