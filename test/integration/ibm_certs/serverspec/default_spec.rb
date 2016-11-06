require 'spec_helper'

describe command('/opt/IBM/WebSphere/Plugins/java/jre/bin/ikeycmd -cert -list -db /root/keystores/keystore.kdb -pw dummy') do
  its(:stdout) { should match(/mydomain.com/) }
  its(:stdout) { should match(/myotherdomain.com/) }
  its(:stdout) { should match(/chef-websphere-test.com/) }
end

describe command('/opt/IBM/WebSphere/Plugins/java/jre/bin/ikeycmd -cert -getdefault -db /root/keystores/keystore.kdb -pw dummy') do
  its(:stdout) { should match(/chef-websphere-test.com/) }
end

files = %w(keystore.kdb keystore.rdb keystore.sth mydomain.com.cer)
files.each do |f|
  describe file("/root/keystores/#{f}") do
    it { should exist }
    it { should be_owned_by 'jim' }
    it { should be_mode 600 }
  end
end
