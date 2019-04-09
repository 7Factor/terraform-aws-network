resource "aws_security_group" "utility_hosts" {
  name        = "utility-hosts"
  description = "Opens SSH to utility hosts like bastions."
  vpc_id      = "${aws_vpc.primary_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_ingress_cidr}"]
  }

  // Per docs, this means allow all leaving.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Utility Hosts (allows SSH)"
  }
}

resource "aws_security_group" "allow_utility_access" {
  name        = "ssh-access-from-utilities"
  description = "Opens SSH to boxes accessible from bastions."
  vpc_id      = "${aws_vpc.primary_vpc.id}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${aws_security_group.utility_hosts.id}"]
  }

  // Per docs, this means allow all leaving.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "Allow SSH from utility hosts"
  }
}
