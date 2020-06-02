require 'awspec'
require 'hcl/checker'

require_relative 'util'

TFVARS = HCL::Checker.parse(File.open('testing.tfvars').read())
ENVVARS = eval(ENV['KITCHEN_KITCHEN_TERRAFORM_OUTPUTS'])

describe vpc(ENVVARS[:vpc_id][:value]) do
  it { should exist }
  it { should be_available }
  it { should have_tag('Name').value('Primary VPC') }

  it 'should have the correct cidr blocks' do
    cidr_blocks = subject.cidr_block_association_set.map {|item| item.cidr_block}

    expect(cidr_blocks).to include TFVARS['vpc_primary_cidr']
    expect(cidr_blocks).to include TFVARS['vpc_addl_address_space'][0]
    expect(cidr_blocks).to include TFVARS['utility_subnet_cidr']
  end
end

describe 'the public subnets' do
  describe subnet(ENVVARS[:public_subnets][:value][0]) do
    assert_subnet_configuration('Public', 'us-east-1a')
  end

  describe subnet(ENVVARS[:public_subnets][:value][1]) do
    assert_subnet_configuration('Public', 'us-east-1b')
  end
end

describe 'the private subnets' do
  describe subnet(ENVVARS[:private_subnets][:value][0]) do
    assert_subnet_configuration('Private', 'us-east-1a')
  end

  describe subnet(ENVVARS[:private_subnets][:value][1]) do
    assert_subnet_configuration('Private', 'us-east-1b')
  end
end

describe 'the additional private subnets' do
  describe subnet(ENVVARS[:addl_private_subnets][:value][0]) do
    assert_subnet_configuration('Private Only', 'us-east-1c')
  end

  describe subnet(ENVVARS[:addl_private_subnets][:value][1]) do
    assert_subnet_configuration('Private Only', 'us-east-1d')
  end
end

describe internet_gateway(ENVVARS[:internet_gateway_id][:value]) do
  it { should exist }
  it { should be_attached_to(ENVVARS[:vpc_id][:value]) }
  it { should have_tag('Name').value('IGW for public subnets')}
end

describe 'the nat' do
  describe eip(ENVVARS[:nat_eip][:value]) do
    it { should exist }
  end

  describe nat_gateway(ENVVARS[:nat_gateway_id][:value]) do
    it { should exist }
    it { should be_available }
    it { should have_eip(ENVVARS[:nat_eip][:value]) }
    it { should have_tag('Name').value('NAT Gateway for private subnets')}
    it { should belong_to_vpc(ENVVARS[:vpc_id][:value]) }
  end
end