require 'awspec'
require 'hcl/checker'

require_relative 'util'

TFVARS = HCL::Checker.parse(File.open('testing.tfvars').read())
ENVVARS = eval(ENV['KITCHEN_KITCHEN_TERRAFORM_OUTPUTS'])

describe security_group(ENVVARS[:utility_hosts_sg][:value]) do
  is_ssh_accessible('Utility Hosts (allows SSH)', TFVARS['ssh_ingress_cidr'])
end

describe security_group(ENVVARS[:allow_utility_access_sg][:value]) do
  is_ssh_accessible('Allow SSH from utility hosts', ENVVARS[:utility_hosts_sg][:value])
end