require 'awspec'
require 'hcl/checker'

require_relative 'util'

TFVARS = HCL::Checker.parse(File.open('testing.tfvars').read())
ENVVARS = eval(ENV['KITCHEN_KITCHEN_TERRAFORM_OUTPUTS'])

describe 'the public routes' do
  describe route_table(ENVVARS[:public_route_table_id][:value]) do
    it { should exist }
    it { should have_tag('Name').value('Public routing table') }
    its(:vpc_id) { should eq ENVVARS[:vpc_id][:value] }

    describe 'the internet gateway association' do
      it { should have_route('0.0.0.0/0').target(gateway: ENVVARS[:internet_gateway_id][:value]) }
    end

    describe 'the public subnet associations' do
      it { should have_subnet(ENVVARS[:public_subnets][:value][0]) }
      it { should have_subnet(ENVVARS[:public_subnets][:value][1]) }
    end

    describe 'the utility subnet association' do
      it { should have_subnet(ENVVARS[:utility_subnet_id][:value]) }
    end

    assert_local_associations
  end
end

describe 'the private routes' do
  describe route_table(ENVVARS[:private_route_table_id][:value]) do
    it { should exist }
    it { should have_tag('Name').value('Private routing table') }
    its(:vpc_id) { should eq ENVVARS[:vpc_id][:value] }

    describe 'the nat gateway association' do
      it { should have_route('0.0.0.0/0').target(nat: ENVVARS[:nat_gateway_id][:value]) }
    end

    assert_local_associations
  end
end