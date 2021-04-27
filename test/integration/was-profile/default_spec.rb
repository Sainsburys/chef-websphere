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
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/AppProfile1_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{dmgr\(cells/MyNewCell/nodes/MyNewNode/servers/dmgr}) }
end

# check dmgr security attribtue is set
describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminTask.isAppSecurityEnabled()"') do
  its(:stdout) { should match(/true/) }
end

services = %w[Dmgr01 AppProfile1_node]
services.each do |service|
  describe service(service) do
    it { should be_enabled }
    it { should be_running }
  end
end

describe file('/etc/init.d/Dmgr01') do
  its(:content) { should match(/startScript=startManager.sh/) }
end
describe file('/etc/init.d/AppProfile1_node') do
  its(:content) { should match(/startScript=startServer.sh/) }
end

ports = %w[9043 8879]
ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

# java tests
describe command('/opt/IBM/WebSphere/AppServer/bin/managesdk.sh -listEnabledProfile -profileName AppProfile1') do
  its(:stdout) { should match(/Node AppProfile1_node SDK name: 1.8_64/) }
end
