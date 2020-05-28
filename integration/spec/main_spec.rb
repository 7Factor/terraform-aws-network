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
    cidr_blocks = subject.cidr_block_association_set.map {|cidr_block| cidr_block}

    expect(cidr_blocks[0].cidr_block).to eq TFVARS['vpc_primary_cidr']
    expect(cidr_blocks[1].cidr_block).to eq TFVARS['vpc_addl_address_space'][0]
    expect(cidr_blocks[2].cidr_block).to eq TFVARS['utility_subnet_cidr']
  end
end

describe 'the public subnets' do
  describe subnet(ENVVARS[:public_subnets][:value][0]) do
    has_correct_configuration('Public', 'us-east-1a')
  end

  describe subnet(ENVVARS[:public_subnets][:value][1]) do
    has_correct_configuration('Public', 'us-east-1b')
  end
end

describe 'the private subnets' do
  describe subnet(ENVVARS[:private_subnets][:value][0]) do
    has_correct_configuration('Private', 'us-east-1a')
  end

  describe subnet(ENVVARS[:private_subnets][:value][1]) do
    has_correct_configuration('Private', 'us-east-1b')
  end
end

describe 'the additional private subnets' do
  describe subnet(ENVVARS[:addl_private_subnets][:value][0]) do
    has_correct_configuration('Private Only', 'us-east-1c')
  end

  describe subnet(ENVVARS[:addl_private_subnets][:value][1]) do
    has_correct_configuration('Private Only', 'us-east-1d')
  end
end

describe internet_gateway(ENVVARS[:internet_gateway_id][:value]) do
  it { should exist }
  it { should be_attached_to(ENVVARS[:vpc_id][:value]) }
  it { should have_tag('Name').value('IGW for public subnets')}
end
