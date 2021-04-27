include_recipe 'websphere-test::was_install_basic'
include_recipe 'websphere-test::was_fixpack_java8'

# JAVA SDK version found with bin/managesdk.sh -listAvailable -verbose
websphere_dmgr 'Dmgr01 create' do
  profile_name 'Dmgr01'
  cell_name 'MyNewCell'
  node_name 'MyNewNode'
  admin_user 'admin'
  admin_password 'admin'
  java_sdk '1.8_64'
  security_attributes ({
    'newvalue' => "[['appEnabled','true']]"
  })
  timeout node['websphere-test']['dmgr_timeout']
  action [:create, :start]
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
  java_sdk '1.8_64'
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
  server_name 'ClusterServer1-node'
  server_node 'CustomProfile1_node'
  run_user 'was'
  run_group 'was'
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
