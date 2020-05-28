require 'awspec'
require 'hcl/checker'

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