require 'spec_helper'

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin -password '\
  'admin -c "AdminServerManagement.listServers(\'\', \'\')"') do
  its(:stdout) { should match(%r{dmgr\(cells/MyNewCell/nodes/Dmgr01_node/servers}) }
  its(:stdout) { should match(%r{nodeagent\(cells/MyNewCell/nodes/Custom_node/servers/nodeagent}) }
  its(:stdout) { should match(%r{app_server1\(cells/MyNewCell/nodes/Custom_node/servers/app_server1}) }


end
