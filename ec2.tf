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
  subnet_id            = aws_subnet.utility_subnet.id
  iam_instance_profile = aws_iam_instance_profile.bastion_profile.id
  key_name             = var.bastion_key_name

  tags = {
    "Patch Group" = local.bastion_patch_group_name
    Name          = "${var.vpc_name} Bastion Host ${var.bastion_count}"
  }

  vpc_security_group_ids = [aws_security_group.utility_hosts.id]

  user_data = base64encode(templatefile("${path.module}/bastion.tftpl", {}))
}

resource "aws_eip" "bastion_eips" {
  for_each                  = toset(aws_instance.bastion_hosts.*.id)
  vpc                       = true
  instance                  = each.key
  public_ipv4_pool          = "amazon"
  depends_on                = [aws_internet_gateway.igw, aws_instance.bastion_hosts]
}