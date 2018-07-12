include_recipe 'websphere-test::was_install_basic'
include_recipe 'websphere-test::was_fixpack_java7'

websphere_dmgr 'Dmgr01 create' do
  profile_name 'Dmgr01'
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  security_attributes ({
    'newvalue' => "[['appEnabled','true']]"
  })
  action [:create, :start]
end

# App server profile tests
## Create, federate, start and set custom attributes
## Create, start, federate
## delete, create, federate, and set custom attributes start with same name
websphere_profile 'AppProfile1 create/federate/start' do
  profile_name 'AppProfile1'
  admin_user 'admin'
  admin_password 'admin'
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['maximumStartupAttempts', '2'], ['pingTimeout', '99'], ['pingInterval', '666'], ['autoRestart', 'false'], ['nodeRestartState', 'RUNNING']]"
      },
      'jvmEntries' => {
        'newvalue' => "[['debugMode', 'true']], [['systemProperties',[['name','my_system_property'],['value','testing123']]]"
      }
    }
  })
  action [:create, :federate, :start]
end

# Custom profile tests
## create two Custom Nodes to use in cluster
## create, federate both nodes.
## delete, create, federate one of the nodes custom nodes with same name
websphere_profile 'CustomProfile1 create/federate' do
  profile_name 'CustomProfile1'
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
  java_sdk '1.7.1_64'
  action [:create, :federate]
end

# Cluster tests
# ## create cluster and add additional server
websphere_cluster 'MyCluster' do
  admin_user 'admin'
  admin_password 'admin'
  action [:create]
end

websphere_cluster_member 'ClusterServer1' do
  cluster_name 'MyCluster'
  server_node 'CustomProfile1_node'
  admin_user 'admin'
  admin_password 'admin'
  member_weight 15
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['maximumStartupAttempts', '2'], ['pingInterval', '222'], ['autoRestart', 'true'], ['nodeRestartState', 'PREVIOUS']]"
      },
      'jvmEntries' => {
        'newvalue' => "[['debugMode', 'true'], ['initialHeapSize', 1024], ['maximumHeapSize', 3072], ['systemProperties',[[['name','my_system_property'],['value','testing123']]]]]"
      }
    }
  })
  action [:create, :start]
end

# deploy an application on the cluster
# start it, stop it, start it again.
# Stop it when it's already stopped.
remote_file '/tmp/sample.war' do
  source 'https://s3-eu-west-1.amazonaws.com/jsidentity/was_sample_apps/sample.war'
  mode '0755'
  action :create
end

websphere_app 'sample_app_cluster' do
  app_file '/tmp/sample.war'
  cluster_name 'MyCluster'
  admin_user 'admin'
  admin_password 'admin'
  action [:deploy_to_cluster, :start]
end
