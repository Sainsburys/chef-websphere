require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'spec_helper'

describe 'websphere-test::ibm_certs' do
  cached(:chef_run) do
    stub_commands
    ChefSpec::SoloRunner.new(step_into: 'ibm_cert') do |node|
      node.automatic['websphere-test']['passport_advantage']['user'] = 'dummyuser'
      node.automatic['websphere-test']['passport_advantage']['password'] = 'dummypw'
    end.converge('websphere-test::ibm_certs')
  end

  before do
    allow(File).to receive(:exist?).with(anything).and_call_original
    allow(File).to receive(:exist?).with('/root/keystores/keystore.kdb').and_return true
    allow(File).to receive(:exist?).with('/root/keystores/cert_to_import.cer').and_return true
  end

  it 'Creates the key store' do
    expect(chef_run).to create_directory('/root/keystores')
    expect(chef_run).to run_execute('create kdb /root/keystores/keystore.kdb').with(
      command: %r{-keydb -create -db /root/keystores/keystore.kdb -pw dummy -type cms -expire 7300 -stash},
      sensitive: false
    )
  end

  it 'Creates certificate mydomain.com' do
    expect(chef_run).to run_execute('create cert mydomain.com').with(
      command: %r{-cert -create -db /root/keystores/keystore.kdb -pw dummy},
      sensitive: false
    )
  end

  it 'Sets the permissions on the file' do
    expect(chef_run).to run_execute('set perms').with(
      command: 'chown jim /root/keystores/* && chmod 600 /root/keystores/*'
    )
  end

  it 'Extracts certificate mydomain.com' do
    expect(chef_run).to run_execute('extract cert mydomain.com').with(
      command: %r{-cert -extract -db /root/keystores/keystore.kdb -pw dummy},
      sensitive: false
    )
  end

  it 'Adds the certificate myotherdomain.com' do
    expect(chef_run).to run_execute('add cert myotherdomain.com to /root/keystores/keystore.kdb').with(
      command: %r{-cert -add -pw dummy -label myotherdomain.com -trust enable -file /root/keystores/cert_to_import.cer -db /root/keystores/keystore.kdb},
      sensitive: false
    )
  end
end
