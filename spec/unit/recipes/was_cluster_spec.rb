require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'spec_helper'

describe 'websphere-test::was_cluster' do
  cached(:chef_run) do
    stub_commands
    ChefSpec::ServerRunner.new(
      step_into: %w(websphere_dmgr websphere_profile websphere_cluster websphere_cluster_member websphere_ihs websphere_app),
      platform: 'centos',
      version: '6.6'
    ) do |node|
      node.set['websphere-test']['passport_advantage']['user'] = 'dummyuser'
      node.set['websphere-test']['passport_advantage']['password'] = 'dummypw'
    end.converge('websphere-test::was_cluster')
  end

  it 'includes recipe websphere-test::was_install' do
    expect(chef_run).to include_recipe('websphere-test::was_install')
  end

  it 'creates Dmgr01 profile with manageprofiles.sh' do
    expect(chef_run).to run_execute('manage_profiles ./manageprofiles.sh -create Dmgr01').with(sensitive: true)
  end

  it 'creates an init script with attributes' do
    expect(chef_run).to create_template('/etc/init.d/Dmgr01')
  end

  it 'runs a ruby_block to set security attributes' do
    expect(chef_run).to run_ruby_block('set security attributes')
  end

  it 'enables dmgr as a service' do
    expect(chef_run).to enable_service('Dmgr01')
  end

  it 'starts dmgr' do
    expect(chef_run).to run_execute('start dmgr profile: Dmgr01').with(command: './startManager.sh -profileName Dmgr01')
  end
end
