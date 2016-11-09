require 'spec_helper'

# webserver tests
describe command('/opt/IBM/WebSphere/Toolbox/WCT/wctcmd.sh -tool pct -listDefinitionLocations') do
  its(:stdout) { should match(/Name: MyWebserver1/) }
  its(:stdout) { should match(%r{Path: /opt/IBM/WebSphere/Plugins}) }
end

describe file('/opt/IBM/WebSphere/Plugins/logs/config/configure_IHS_webserver.log') do
  its(:content) { should match(/Configuration Completed Successfully/) }
end

describe file('/opt/IBM/HTTPServer/logs/postinstall/postinstall.log') do
  its(:content) { should match(/INSTCONFSUCCESS/) }
end

describe file('/opt/IBM/WebSphere/Plugins/logs/config/installIHSPlugin.log') do
  its(:content) { should match(/Install complete/) }
  its(:content) { should_not match(/Could not locate config file/) }
end

## plugin config has propogated
cfg_files = %w(
  /opt/IBM/WebSphere/Plugins/config/MyWebserver1/plugin-cfg.xml
  /opt/IBM/WebSphere/Plugins/config/templates/plugin-cfg.xml
  /opt/IBM/WebSphere/AppServer/profiles/Dmgr01/config/cells/MyNewCell/nodes/Custom01_node/servers/MyWebserver1/plugin-cfg.xml
  /opt/IBM/WebSphere/AppServer/profiles/Custom01/config/cells/plugin-cfg.xml
  /opt/IBM/WebSphere/AppServer/profiles/Dmgr01/config/cells/plugin-cfg.xml
)

cfg_files.each do |f|
  describe file(f) do
    it { should exist }
  end
end

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminServerManagement.listServers(\'WEB_SERVER\', \'\')"') do
  its(:stdout) { should match(%r{MyWebserver1\(cells/MyNewCell/nodes/Custom01_node/servers/MyWebserver1}) }
end

describe file('/opt/IBM/HTTPServer/conf/httpd.conf') do
  its(:content) { should match(%r{LoadModule was_ap22_module /opt/IBM/WebSphere/Plugins/bin/64bits/mod_was_ap22_http.so}) }
  its(:content) { should match(%r{WebSpherePluginConfig /opt/IBM/WebSphere/Plugins/config/MyWebserver1/plugin-cfg.xml}) }
end

describe port(80) do
  it { should be_listening }
end

describe service('ibm-httpd') do
  it { should be_enabled }
end

describe process('httpd') do
  it { should be_running }
end
