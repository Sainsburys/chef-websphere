include_recipe 'websphere-test::was_install'

websphere_dmgr 'Dmgr01' do
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
websphere_profile 'AppProfile1' do
  admin_user 'admin'
  admin_password 'admin'
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['maximumStartupAttempts', '2'], ['pingTimeout', '99'], ['pingInterval', '666'], ['autoRestart', 'false'], ['nodeRestartState', 'RUNNING']]"
      },
      'jvmEntries' => {
        'newvalue' => "[['debugMode', 'true']]"
      }
    }
  })
  action [:create, :federate, :start]
end

websphere_profile 'AppProfile2' do
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start, :federate]
end

websphere_profile 'AppProfile1' do
  admin_user 'admin'
  admin_password 'admin'
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['maximumStartupAttempts', '2'], ['pingTimeout', '99'], ['pingInterval', '666'], ['autoRestart', 'false'], ['nodeRestartState', 'RUNNING']]"
      },
      'jvmEntries' => {
        'newvalue' => "[['debugMode', 'true']]"
      }
    }
  })
  java_sdk '1.7.1_64'
  action [:delete, :create, :federate, :start]
end

# Custom profile tests
## create two Custom Nodes to use in cluster
## create, federate both nodes.
## delete, create, federate one of the nodes custom nodes with same name
websphere_profile 'CustomProfile1' do
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :federate]
end

websphere_profile 'CustomProfile2' do
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :federate]
end

websphere_profile 'CustomProfile1' do
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
  action [:delete, :create, :federate]
end

# Cluster tests
## create vanilla cluster without a template
## add new server to cluster on CustomProfile1_node with set weight
## add new server to cluster on CustomProfile2_node with different weight
## delete and recreate both servers with same name
## delete appservers, delete nodes/profiles and delete cluster.

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
        'newvalue' => "[['debugMode', 'true']]"
      }
    }
  })
  action [:create, :start]
end

websphere_cluster_member 'ClusterServer2' do
  cluster_name 'MyCluster'
  server_node 'CustomProfile2_node'
  admin_user 'admin'
  admin_password 'admin'
  member_weight 5
  action [:create, :start]
end

# delete both servers and cluster.
websphere_cluster_member 'ClusterServer1' do
  cluster_name 'MyCluster'
  server_node 'CustomProfile1_node'
  admin_user 'admin'
  admin_password 'admin'
  member_weight 15
  action [:delete]
end
websphere_cluster_member 'ClusterServer2' do
  cluster_name 'MyCluster'
  server_node 'CustomProfile2_node'
  admin_user 'admin'
  admin_password 'admin'
  member_weight 5
  action [:delete]
end
websphere_cluster 'MyCluster' do
  admin_user 'admin'
  admin_password 'admin'
  action [:delete]
end

# recreate cluster and both servers with same name
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
        'newvalue' => "[['debugMode', 'true'], ['initialHeapSize', 1024], ['maximumHeapSize', 3072]]"
      }
    }
  })
  action [:create, :start]
end

websphere_cluster_member 'ClusterServer2' do
  cluster_name 'MyCluster'
  server_node 'CustomProfile2_node'
  admin_user 'admin'
  admin_password 'admin'
  member_weight 5
  action [:create, :start]
end

websphere_ihs 'MyWebserver1' do
  config_type 'local_distributed'
  profile_name 'AppProfile1'
  node_name 'AppProfile1_node'
  map_to_apps true
  ihs_port '80'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end

websphere_ihs 'MyWebserver1' do
  config_type 'local_distributed'
  profile_name 'AppProfile1'
  node_name 'AppProfile1_node'
  map_to_apps true
  ihs_port '80'
  admin_user 'admin'
  admin_password 'admin'
  action [:stop, :delete, :create, :start]
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
  action [:deploy_to_cluster, :start, :stop]
end

websphere_app 'sample_app_cluster' do
  app_file '/tmp/sample.war'
  cluster_name 'MyCluster'
  admin_user 'admin'
  admin_password 'admin'
  action [:stop, :start]
end

# deploy an unclustered application on the managed appserver
# start it and stop it. start it again.
websphere_app 'sample_app' do
  app_file '/tmp/sample.war'
  server_name 'AppProfile1_server'
  node_name 'AppProfile1_node'
  admin_user 'admin'
  admin_password 'admin'
  action [:deploy_to_server, :start]
end

websphere_app 'sample_app' do
  app_file '/tmp/sample.war'
  server_name 'AppProfile1_server'
  node_name 'AppProfile1_node'
  admin_user 'admin'
  admin_password 'admin'
  action [:stop, :start]
end

# create and delete virtual host aliases
websphere_vhost_alias 'test add vhost alias' do
  vhost_name 'default_host'
  alias_host  '*'
  alias_port  '11111'
  admin_user 'admin'
  admin_password 'admin'
  action :create
end

websphere_vhost_alias 'test delete vhost alias' do
  vhost_name 'default_host'
  alias_host  '*'
  alias_port  '33333'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :delete]
end
