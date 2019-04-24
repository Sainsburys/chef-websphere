require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'spec_helper'

describe 'websphere-test::was_cluster' do
  context 'default settings for each resource' do
    cached(:chef_run) do
      stub_commands
      ChefSpec::SoloRunner.new(
        step_into: %w[websphere_dmgr websphere_profile websphere_cluster websphere_cluster_member websphere_ihs websphere_app websphere_base],
        platform: 'centos'
      ) do |node|
        node.automatic['websphere-test']['passport_advantage']['user'] = 'dummyuser'
        node.automatic['websphere-test']['passport_advantage']['password'] = 'dummypw'
      end.converge('websphere-test::was_cluster')
    end

    %w[
      websphere-test::was_install_basic
      websphere-test::was_fixpack_java8
    ].each do |recipe|
      it "includes recipe #{recipe}" do
        expect(chef_run).to include_recipe(recipe)
      end
    end

    it 'creates Dmgr01 profile with manageprofiles.sh' do
      expect(chef_run).to run_execute('manage_profiles ./manageprofiles.sh -create Dmgr01').with(
        sensitive: true
      )
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
      expect(chef_run).to run_execute('start dmgr profile: Dmgr01').with(
        command: './startManager.sh -profileName Dmgr01',
        cwd: '/opt/IBM/WebSphere/AppServer/profiles/Dmgr01/bin'
      )
    end

    it 'enables Java on the profile' do
      expect(chef_run).to run_execute('enable java 1.8_64 on profile: CustomProfile1').with(
        user: 'was'
      )
    end
  end
  context 'add timeout for DMgr startup' do
    cached(:chef_run) do
      stub_commands
      ChefSpec::SoloRunner.new(
        step_into: %w[websphere_dmgr]
      ) do |node|
        node.automatic['websphere-test']['passport_advantage']['user'] = 'dummyuser'
        node.automatic['websphere-test']['passport_advantage']['password'] = 'dummypw'
        node.automatic['websphere-test']['dmgr_timeout'] = 600
      end.converge('websphere-test::was_cluster')
    end

    it 'starts dmgr with the correct timeout' do
      expect(chef_run).to run_execute('start dmgr profile: Dmgr01').with(
        command: './startManager.sh -profileName Dmgr01 -timeout 600'
      )
    end
  end

  context 'Running on EL7' do
    cached(:chef_run) do
      stub_commands
      ChefSpec::SoloRunner.new(
        step_into: %w[websphere_dmgr websphere_profile],
        platform: 'redhat',
        version: '7.3'
      ) do |node|
        node.automatic['websphere-test']['passport_advantage']['user'] = 'dummyuser'
        node.automatic['websphere-test']['passport_advantage']['password'] = 'dummypw'
      end.converge('websphere-test::was_cluster')
    end

    it 'creates a Deployment Manager runit script with attributes' do
      expect(chef_run).to render_file('/etc/systemd/system/Dmgr01.service').with_content(
        'ExecStop=/opt/IBM/WebSphere/AppServer/profiles/Dmgr01/bin/stopManager.sh -username admin -password admin'
      )
      expect(chef_run).to render_file('/etc/systemd/system/Dmgr01.service').with_content(
        'TimeoutSec=300'
      )
    end
  end
end
