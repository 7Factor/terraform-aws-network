data "aws_ami" "ec2_linux" {
  most_recent = true
  owners      = [137112412989]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

resource "aws_instance" "bastion_hosts" {
  count                = var.bastion_count
  ami                  = data.aws_ami.ec2_linux.id
  instance_type        = var.bastion_instance_type
  subnet_id            = aws_subnet.utility_subnets[count.index].id
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.id
  key_name             = var.bastion_key_name

  tags = {
    "Patch Group" = local.bastion_patch_group_name
    Name          = "${var.vpc_name} Bastion Host ${count.index}"
  }

  vpc_security_group_ids = [aws_security_group.utility_hosts.id]

  user_data = base64encode(templatefile("${path.module}/bastion.tftpl", {}))

  lifecycle {
    precondition {
      condition     = var.bastion_count <= length(var.az_subnet_pairs)
      error_message = "You must have an availability zone declared for each bastion host. Multiple bastion hosts in each availability zone is not supported"
    }
  }
}
