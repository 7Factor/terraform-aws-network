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
  source  = "7Factor/networking/aws"
  version = "~> 1"

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

  bastion_route53 = {
    zone = {
      name = "7factor.io"
    }
    record = {
      name = "db.7factor.io"
    }
  }
}
```

### EIP and Route53 behavior
If `bastion_count = 1` and `bastion_route53` is provided, the bastion will be assigned an EIP and a Route53 record will be created for it. 
If `bastion_count > 1` or `bastion_route53` is not provided, the bastion will not be assigned an EIP and no Route53 record will be created for it.
This will allow you to define an EIP and Route53 record for a single bastion, but not for a bastion autoscaling group.

## Migrating to Terraform Registry version

We have migrated this module to the 
[Terraform Registry](https://registry.terraform.io/modules/7Factor/networking/aws/latest)! Going forward, you should
endeavour to use the registry as the source for this module. It is also **highly recommended** that you migrate existing
projects to the new source at your earliest convenience. Using it in this way, you can select a range of versions to use
in your service which allows us to make potentially breaking changes to the module without breaking your service.

### Migration instructions

You need to change the module source from the GitHub url to `7Factor/networking/aws`. This will pull the module from
the Terraform registry. You should also add a version to the module block. See the [example](#example-usage) above for
what this looks like together.

**Major version 1 is intended to maintain backwards compatibility with the old module source.** To use the new module
source and maintain compatibility, set your version to `"~> 1"`. This means you will receive any updates that are
backwards compatible with the old module. 
