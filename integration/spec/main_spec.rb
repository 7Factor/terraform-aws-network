require 'awspec'
require 'hcl/checker'

TFVARS = HCL::Checker.parse(File.open('testing.tfvars').read())
ENVVARS = eval(ENV['KITCHEN_KITCHEN_TERRAFORM_OUTPUTS'])

describe vpc(ENVVARS[:vpc_id][:value]) do
  it { should exist }
  it { should be_available }
  it { should have_tag('Name').value('Primary VPC') }
end