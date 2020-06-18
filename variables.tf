# Utility subnet CIDR
variable utility_subnet_cidr {
  description = "CIDR for the utility subnet. This subnet is not HA."
}

variable enable_utility_public_ips {
  default     = true
  description = "Enables public IP addresses for the utility subnet. On by default."
}

variable vpc_name {
  default     = "Primary VPC"
  description = "Name of the VPC. Shows up in tags. Defaults to 'Primary VPC'"
}

# This will actually be a list of maps, which stores information about
# the public/private subnet configuration. Every private subnet needs
# a corresponding public subnet. This is especially usefull if you're
# going to load balance something inside a private subnet.
variable public_private_subnet_pairs {
  type        = list
  description = "A list of maps that connect public and private subnet pairs."
}

# This is a list of additional private subnets with no automatic public
# subnet associated with them. They will be added to the appropriate
# routing table to ensure NAT'd access to the internet.
variable addl_private_subnets {
  type        = list
  default     = []
  description = "A list of private only subnets with no public subnets associated with them. Defaults to empty list."
}

# At least one CIDR Needs to exist on the VPC in order to create it. All other values will be inferred when you
# create your subnets. Magic!
variable vpc_primary_cidr {
  description = "To avoid any irritation with specifying CIDRs that belong on a VPC specify one that's your primary."
}

# List out all the additional address space you need in addition to the primary CIDR. You must include all subnets
# or you will get failures during creation of those subnets.
variable vpc_addl_address_space {
  type        = list
  description = "Additional high level address space to add to the VPC. You must provide this, it can be an empty list."
}

# CIDR for ingress access to bastion hosts.
variable ssh_ingress_cidr {
  default     = "0.0.0.0/0"
  description = "A CIDR describing where the bastion hosts boxes may come in from. This is defaulted to 0.0.0.0/0; change if you have a VPN."
}

##### BASTION HOST VARIABLES #####

# The number of bastion hosts to create. Defaults to 1.
variable bastion_count {
  default     = 1
  description = "The number of bastion hosts to create. Defaults to one."
}

# The instance type for bastions. Defaults to the free tier.
variable bastion_instance_type {
  description = "The bastion host type."
}

# The name of the key for bastion hosts.
variable bastion_key_name {
  description = "The key name for the bastion host without.pem on the end. Make sure you have access to it."
}
