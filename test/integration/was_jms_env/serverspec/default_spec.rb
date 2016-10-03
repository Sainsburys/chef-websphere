require 'spec_helper'

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
