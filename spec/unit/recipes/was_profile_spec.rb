require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'spec_helper'

describe 'websphere-test::was_profile' do
  context 'default settings for each resource' do
    cached(:chef_run) do
      stub_commands
      ChefSpec::SoloRunner.new(
        step_into: %w[websphere_profile websphere_base websphere_dmgr helpers],
        platform: 'centos'
      ) do |node|
        node.automatic['websphere-test']['passport_advantage']['user'] = 'dummyuser'
        node.automatic['websphere-test']['passport_advantage']['password'] = 'dummypw'
      end.converge('websphere-test::was_profile')
    end

    it 'includes basic recipe' do
      expect(chef_run).to include_recipe('websphere-test::was_install_basic')
    end

    it 'creates AppProfile1 profile with manageprofiles.sh' do
      expect(chef_run).to run_execute('manage_profiles -create AppProfile1').with(
        sensitive: true
      )
    end
  end
end
