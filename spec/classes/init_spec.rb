require 'spec_helper'
describe 'websphere_deployer' do

  context 'with defaults for all parameters' do
    it { should contain_class('websphere_deployer') }
  end
end
