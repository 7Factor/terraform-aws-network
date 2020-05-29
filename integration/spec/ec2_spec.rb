require 'awspec'
require 'hcl/checker'

TFVARS = HCL::Checker.parse(File.open('testing.tfvars').read())
ENVVARS = eval(ENV['KITCHEN_KITCHEN_TERRAFORM_OUTPUTS'])

describe 'the bastion hosts' do
  describe ec2(ENVVARS[:bastion_host_ids][:value][0]) do
    it { should exist }
    it { should be_running }
    it { should belong_to_vpc(ENVVARS[:vpc_id][:value]) }
    it { should have_security_group('utility-hosts') }
    it { should have_tag('Name').value('Bastion Host 1') }
    it { should belong_to_subnet(ENVVARS[:utility_subnet_id][:value]) }
    its(:image_id) { should eq ENVVARS[:aws_ami_id][:value]}
    its(:instance_type) { should eq 't2.micro' }
    its(:public_ip_address) { should eq ENVVARS[:bastion_host_public_ips][:value][0]}
    its(:private_ip_address) { should eq ENVVARS[:bastion_host_private_ips][:value][0]}
  end
end
