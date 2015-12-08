require 'chefspec'
require 'chefspec/berkshelf'

describe 'websphere::default' do
  before(:each) do
    stub_command('sudo -V').and_return('blarg')
  end

  it 'should install websphere' do
    expect(chef_run).to run_execute('install')
  end
end
