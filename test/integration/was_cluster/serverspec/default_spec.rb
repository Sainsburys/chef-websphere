require 'spec_helper'

describe group('ibm') do
  it { should exist }
end

describe user('ibm') do
  it { should exist }
  it { belong_to_group 'ibm' }
end

describe file('/opt/IBM/InstallationManager/eclipse/tools/imcl') do
  it { should exist }
end

describe command('/opt/IBM/InstallationManager/eclipse/tools/imcl listInstalledPackages') do
  its(:stdout) { should match(/com.ibm.websphere.ND.v85_8.5.5008.20151112_0939/) }
  its(:stdout) { should match(/com.ibm.websphere.IBMJAVA.v71_7.1.3010.20151112_0058/) }
  its(:stdout) { should match(/com.ibm.websphere.PLG.v85.*/) }
  its(:stdout) { should match(/com.ibm.websphere.IHS.v85.*/) }
  its(:stdout) { should match(/com.ibm.websphere.WCT.v85.*/) }
end

describe command('/opt/IBM/Websphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin -password '\
  'admin -c "AdminServerManagement.listServers(\'\', \'\')"') do
  its(:stdout) { should match(%r{dmgr\(cells/MyNewCell/nodes/Dmgr01_node/servers}) }
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/AppProfile1_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/AppProfile2_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{AppProfile1_server\(cells/MyNewCell/nodes/AppProfile1_node/servers/AppProfile1_server}) }
  its(:stdout) { should match(%r{AppProfile2_server\(cells/MyNewCell/nodes/AppProfile2_node/servers/AppProfile2_server}) }
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/CustomProfile1_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/CustomProfile2_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{ClusterServer1\(cells/MyNewCell/nodes/CustomProfile1_node/servers/ClusterServer1}) }
  its(:stdout) { should match(%r{ClusterServer2\(cells/MyNewCell/nodes/CustomProfile2_node/servers/ClusterServer2}) }
end

services = %w(Dmgr01 AppProfile1_node AppProfile2_node CustomProfile1_node CustomProfile2_node)
services.each do |service|
  describe service(service) do
    it { should be_enabled }
    it { should be_running }
  end
end

describe file('/opt/IBM/Websphere/AppServer/profiles/Dmgr01/config/cells/MyNewCell/nodes/AppProfile1_node/servers/AppProfile1_server/server.xml') do
  its(:content) { should match(/maximumStartupAttempts="2"/) }
  its(:content) { should match(/pingTimeout="99"/) }
  its(:content) { should match(/pingInterval="666"/) }
  its(:content) { should match(/autoRestart="false"/) }
  its(:content) { should match(/nodeRestartState="RUNNING"/) }
  its(:content) { should match(/debugMode="true"/) }
end

ports = %w(9043)
ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

# java tests
describe command('/opt/IBM/Websphere/AppServer/bin/managesdk.sh -listEnabledProfile -profileName AppProfile1') do
  its(:stdout) { should match(/Server AppProfile1_server SDK name: 1.7.1_64/) }
end

# cluster tests
describe command('/opt/IBM/Websphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost '\
  '-user admin -password admin -c "AdminClusterManagement.checkIfClusterExists(\'MyCluster\')"') do
  its(:stdout) { should match(/true/) }
end

describe command('/opt/IBM/Websphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin -password admin '\
  '-c "AdminClusterManagement.listClusterMembers(\'MyCluster\')"') do
  its(:stdout) { should match(/cluster MyCluster has 2 members/) }
  its(:stdout) { should match(/Cluster member: ClusterServer1/) }
  its(:stdout) { should match(/Cluster member: ClusterServer2/) }
end

# application tests
describe command('curl https://localhost:9443/ -ik') do
  its(:stdout) { should match(/This is the home page for a sample application/) }
end

describe command('curl https://localhost:9443/hello.jsp -ik') do
  its(:stdout) { should match(/This is the output of a JSP page/) }
end

describe command('curl https://localhost:9443/hello -ik') do
  its(:stdout) { should match(/This is the output of a servlet/) }
end

# webserver tests
describe command('/opt/IBM/Websphere/Toolbox/WCT/wctcmd.sh -tool pct -listDefinitionLocations') do
  its(:stdout) { should match(/Name: MyWebserver1/) }
  its(:stdout) { should match(%r{Path: /opt/IBM/Websphere/Plugins}) }
end

describe file('/opt/IBM/Websphere/Plugins/logs/config/configure_IHS_webserver.log') do
  its(:content) { should match(/Configuration Completed Successfully/) }
end

describe file('/opt/IBM/Websphere/Plugins/logs/config/installIHSPlugin.log') do
  its(:content) { should_not match(/Could not locate config file/) }
end

## plugin config has propogated
cfg_files = %w(
  /opt/IBM/Websphere/Plugins/config/MyWebserver1/plugin-cfg.xml
  /opt/IBM/Websphere/Plugins/config/templates/plugin-cfg.xml
  /opt/IBM/Websphere/AppServer/profiles/AppProfile1/config/cells/MyNewCell/nodes/AppProfile1_node/servers/MyWebserver1/plugin-cfg.xml
  /opt/IBM/Websphere/AppServer/profiles/AppProfile1/config/cells/plugin-cfg.xml
  /opt/IBM/Websphere/AppServer/profiles/CustomProfile2/config/cells/plugin-cfg.xml
  /opt/IBM/Websphere/AppServer/profiles/AppProfile2/config/cells/plugin-cfg.xml
  /opt/IBM/Websphere/AppServer/profiles/Dmgr01/config/cells/MyNewCell/nodes/AppProfile1_node/servers/MyWebserver1/plugin-cfg.xml
  /opt/IBM/Websphere/AppServer/profiles/Dmgr01/config/cells/plugin-cfg.xml
  /opt/IBM/Websphere/AppServer/profiles/CustomProfile1/config/cells/plugin-cfg.xml
)

cfg_files.each do |f|
  describe file(f) do
    it { should exist }
  end
end

describe command('/opt/IBM/Websphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminServerManagement.listServers(\'WEB_SERVER\', \'\')"') do
  its(:stdout) { should match(%r{MyWebserver1\(cells/MyNewCell/nodes/AppProfile1_node/servers/MyWebserver1}) }
end

describe file('/opt/IBM/HTTPServer/conf/httpd.conf') do
  its(:content) { should match(%r{LoadModule was_ap22_module /opt/IBM/Websphere/Plugins/bin/64bits/mod_was_ap22_http.so}) }
  its(:content) { should match(%r{WebSpherePluginConfig /opt/IBM/Websphere/Plugins/config/MyWebserver1/plugin-cfg.xml}) }
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
