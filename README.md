# AWS Network Configuration via Terraform

This repo contains all the terraform for creating our network elements. This
particular design supports a public/private subnet configuration with as many
CIDR addresses as you'd want. Private subnets will generate corresponding
public subnets in the event that you want to load balance something in those
private subnets (like a web server); additionally routing tables and NAT
gateways will be generated to handle routing to the internet.

## How to Use This

Check the variables files for the appropriate configuration depending on your
environment, and run terraform apply. You should
[read the documentation](https://www.terraform.io/docs/configuration/index.html)
on how to use TF before you really do much with it else you might blow something
up. However, not to worry. That's why we have this system in place--if you blow
it away we can simply rebuild it with a few commands.

## Summary

In this doc we'll describe at a very high level what's going on, but you should
really read the variable definitions for development and prod in order to gain
a complete understanding of the details. These scripts are geared only towards
the network design of our development and production environments. You'll find
no EC2 instances provisioned here outside of a lone bastion host for accessing
private subnets.

**Primary VPC**: Currently we have a single VPC that holds all our production
build pipeline and any other elements that we use to run the business. The CIDR
blocks are outlined in the appropriate configuration variables. Inside this VPC
we have the following network elements:

- *Private Subnets*: These subnets will be the home for all sensitive servers
such as web and API servers. They will be routed to the internet through a NAT
gateway and the appropriate routing rules in the VPC.
- *Public Subnets*: These subnets are required so that AWS application load
balancers can reach traffic inside the private subnets. There should never be
any actual boxes in these subnets.
- *Utility Subnets*: This will hold utility machines such as RDP gateways and
bastion servers. Never host any production elements in this subnet.

## Security Group Guidelines

In general, you should use the principal of least privilege on all machines
that you build in AWS. As such, we design the security groups such that *only
machines with the appropriate roles* will be able to hit other boxes in the
subnet. For example, only the required load balancers and bastion hosts should
be able to hit production web machines sitting behind it. When dealing with
access levels to production boxes, follow these three rules:

1. **Never attach an elastic IP address to a box in a private subnet ever.**
Use the bastion host instead, that's why it's there. Any private subnet should
only be accessible from the jump box. This is just good design.
2. **Never put private infrastructure (like RDS) in public subnets--even if
it's a "staging" database.** RDS boxes will need a subnet group to be created,
ensure it's a private subnet behind a NAT instance.

## Example Usage

```hcl-terraform
module "networking" {
  source = "git@github.com:7Factor/terraform-aws-networking.git"
  public_private_subnet_pairs = [
    {
      az          = "us-east-1a"
      cidr        = "172.0.1.0/24"
      public_cidr = "10.0.1.0/24"
    },
    {
      az          = "us-east-1b"
      cidr        = "172.0.2.0/24"
      public_cidr = "10.0.2.0/24"
    },
  ]
  bastion_instance_type  = "t2.micro"
  terraform_version      = "0.10.7"
  vpc_primary_cidr       = "10.0.0.0/16"
  bastion_key_name       = "name-of-your-bastion-pem"
  utility_subnet_cidr    = "155.0.0.0/16"
  vpc_addl_address_space = ["172.0.0.0/16"]
}
```
