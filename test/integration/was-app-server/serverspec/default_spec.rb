require 'spec_helper'

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin -password '\
  'admin -c "AdminServerManagement.listServers(\'\', \'\')"') do
  its(:stdout) { should match(%r{dmgr\(cells/MyNewCell/nodes/Dmgr01_node/servers}) }
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/Custom_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{app_server1\(cells/MyNewCell/nodes/Custom_node/servers/app_server1}) }
  its(:stdout) { should_not match(%r{app_server2\(cells/MyNewCell/nodes/Custom_node/servers/app_server2}) }
end

services = %w[Dmgr01 Custom_node]
services.each do |service|
  describe service(service) do
    it { should be_enabled }
    it { should be_running }
  end
end

describe file('/opt/IBM/WebSphere/AppServer/profiles/Dmgr01/config/cells/MyNewCell/nodes/Custom_node/servers/app_server1/server.xml') do
  its(:content) { should match(/<jvmEntries.*initialHeapSize="1024".*maximumHeapSize="3072".*debugMode="true"/) }
  its(:content) { should match(/maximumStartupAttempts="2"/) }
  its(:content) { should match(/pingInterval="222"/) }
  its(:content) { should match(/autoRestart="true"/) }
  its(:content) { should match(/nodeRestartState="PREVIOUS"/) }
  its(:content) { should match(/debugMode="true"/) }
  its(:content) { should match(/systemProperties.*name="my_system_property" value="testing123"/) }
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
