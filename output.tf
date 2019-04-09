output "utility_hosts_sg" {
  value       = "${aws_security_group.utility_hosts.id}"
  description = "The SG that utility boxes are assigned enabling SSH."
}

output "allow_utility_access_sg" {
  value       = "${aws_security_group.allow_utility_access.id}"
  description = "Assign this SG to boxes you wish to be accessible from utilities."
}

output "public_subnets" {
  value       = "${aws_subnet.public_subnets.*.id}"
  description = "Public subnet IDs configured with a cooresponding private subnet."
}

output "private_subnets" {
  value       = "${aws_subnet.private_subnets.*.id}"
  description = "Private subnet IDs configured with a corresponding public subnet."
}

output "addl_private_subnets" {
  value       = "${aws_subnet.addl_private_subnets.*.id}"
  description = "Subnets configured with no public pairs. This doesn't mean they don't have a corresponding public subnet."
}

output "basion_host_public_ips" {
  value       = "${aws_instance.bastion_hosts.*.public_ip}"
  description = "A list of public IP addresses for your bastion hosts."
}

output "basion_host_private_ips" {
  value       = "${aws_instance.bastion_hosts.*.private_ip}"
  description = "A list of pribate IP addresses for your bastion hosts."
}

output "vpc_id" {
  value       = "${aws_vpc.primary_vpc.id}"
  description = "The ID of the primary AWS VPC."
}
