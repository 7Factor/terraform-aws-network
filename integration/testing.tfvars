vpc_primary_cidr       = "10.0.0.0/16"
utility_subnet_cidr    = "155.0.0.0/16"
vpc_addl_address_space = ["172.0.0.0/16"]
bastion_instance_type  = "t2.micro"
bastion_key_name       = "bastion-us-east-1"

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

addl_private_subnets = [
  {
    az   = "us-east-1c"
    cidr = "172.0.3.0/24"
  },
  {
    az   = "us-east-1d"
    cidr = "172.0.4.0/24"
  },
]