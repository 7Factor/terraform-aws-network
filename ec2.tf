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

data "template_file" "bastion_template" {
  template = <<EOF
#!/bin/bash
sudo yum -y update
EOF
}

# Cannot use dynamic tags with aws_instance resource
locals {
  tags = {
    "Patch Group" = var.bastion_patchGroup_tag.value,
    Name          = "Bastion Host ${var.bastion_count}"
  }
}


resource "aws_instance" "bastion_hosts" {
  count                = var.bastion_count
  ami                  = data.aws_ami.ec2_linux.id
  instance_type        = var.bastion_instance_type
  subnet_id            = aws_subnet.utility_subnet.id
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.id
  key_name             = var.bastion_key_name
  tags                 = local.tags

  vpc_security_group_ids = [aws_security_group.utility_hosts.id]

  user_data = base64encode(data.template_file.bastion_template.rendered)
}
