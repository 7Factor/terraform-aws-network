data "aws_ami" "ec2_linux" {
  most_recent = true

  owners = [137112412989]

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

resource "aws_instance" "bastion_hosts" {
  count = "${var.bastion_count}"
  ami = "${data.aws_ami.ec2_linux.id}"
  instance_type = "${var.bastion_instance_type}"
  subnet_id = "${aws_subnet.utility_subnet.id}"
  key_name = "${var.bastion_key_name}"

  vpc_security_group_ids = ["${aws_security_group.utility_hosts.id}"]

  user_data = "${base64encode(data.template_file.bastion_template.rendered)}"

  tags = {
    Name = "Bastion Host ${count.index + 1}"
  }
}
