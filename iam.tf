# Creates an empty role so that policies can be attached as needed
resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${replace(lower(var.vpc_name), " ", "-")}-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

resource "aws_iam_role" "bastion_role" {
  name = "${replace(var.vpc_name, " ", "")}BastionRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

data "aws_iam_policy" "aws_ssm_default" {
  name = "AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "add_ssm_for_patching" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = data.aws_iam_policy.aws_ssm_default.arn
}