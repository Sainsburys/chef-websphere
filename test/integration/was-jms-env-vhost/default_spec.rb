describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminJMS.listJMSProviders()"') do
  its(:stdout) { should match(/WebMethodsUMProvider/) }
end

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminJMS.listGenericJMSDestinations()"') do
  its(:stdout) { should match(/My Queue/) }
end

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminJMS.listGenericJMSConnectionFactories()"') do
  its(:stdout) { should match(/My Queue Conection Factory/) }
end

describe command('/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -conntype SOAP -host localhost -user admin '\
  '-password admin -c "AdminTask.showVariables (\'[]\')"') do
  its(:stdout) { should match(/TESTING_1234/) }
end

# virtual host tests
describe file('/opt/IBM/WebSphere/AppServer/profiles/Dmgr01/config/cells/MyNewCell/virtualhosts.xml') do
  its(:content) { should match(%r{<aliases.* hostname="\*" port="11111"/>}) }
  its(:content) { should_not match(%r{<aliases.* hostname="\*" port="33333"/>}) }
end
