describe group('ibm') do
  it { should exist }
end

describe user('ibm') do
  it { should exist }
  its('groups') { should eq ['ibm'] }
end

describe file('/opt/IBM/InstallationManager/eclipse/tools/imcl') do
  it { should exist }
end

describe command('/opt/IBM/InstallationManager/eclipse/tools/imcl listInstalledPackages') do
  its(:stdout) { should match(/com.ibm.websphere.ND.v85_8.5.5014.*/) }
  its(:stdout) { should match(/com.ibm.websphere.IBMJAVA.v80_8.0.*/) }
end

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin -password '\
  'admin -c "AdminServerManagement.listServers(\'\', \'\')"') do
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/CustomProfile1_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{ClusterServer1-node\(cells/MyNewCell/nodes/CustomProfile1_node/servers/ClusterServer1}) }
  its(:stdout) { should match(%r{dmgr\(cells/MyNewCell/nodes/MyNewNode/servers/dmgr}) }
end

# check dmgr security attribtue is set
describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminTask.isAppSecurityEnabled()"') do
  its(:stdout) { should match(/true/) }
end

services = %w[Dmgr01 CustomProfile1_node]
services.each do |service|
  describe service(service) do
    it { should be_enabled }
    it { should be_running }
  end
end

describe file('/etc/init.d/Dmgr01') do
  its(:content) { should match(/startScript=startManager.sh/) }
end
describe file('/etc/init.d/CustomProfile1_node') do
  its(:content) { should match(/startScript=startServer.sh/) }
end

describe file('/opt/IBM/WebSphere/AppServer/profiles/Dmgr01/config/cells/MyNewCell/nodes/CustomProfile1_node/servers/ClusterServer1-node/server.xml') do
  its('owner') { should eq 'was' }
  its('group') { should eq 'was' }
  its(:content) { should match(/<jvmEntries.*initialHeapSize="1024".*maximumHeapSize="3072".*debugMode="true"/) }
  its(:content) { should match(/maximumStartupAttempts="2"/) }
  its(:content) { should match(/pingInterval="222"/) }
  its(:content) { should match(/autoRestart="true"/) }
  its(:content) { should match(/nodeRestartState="PREVIOUS"/) }
  its(:content) { should match(/debugMode="true"/) }
  its(:content) { should match(/systemProperties.*name="my_system_property" value="testing123"/) }
end

ports = %w[9043 8879]
ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe processes(Regexp.new('/opt/IBM/WebSphere/AppServer/java/bin/java.*MyNewCell CustomProfile1_node nodeagent$')) do
  it { should exist }
end

# java tests
describe command('/opt/IBM/WebSphere/AppServer/bin/managesdk.sh -listEnabledProfile -profileName CustomProfile1') do
  its(:stdout) { should match(/Server ClusterServer1-node SDK name: 1.8_64/) }
end

# cluster tests
describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost '\
  '-user admin -password admin -c "AdminClusterManagement.checkIfClusterExists(\'MyCluster\')"') do
  its(:stdout) { should match(/true/) }
end

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin -password admin '\
  '-c "AdminClusterManagement.listClusterMembers(\'MyCluster\')"') do
  its(:stdout) { should match(/Cluster member: ClusterServer1/) }
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
