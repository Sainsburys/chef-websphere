
include_recipe 'websphere-test::was_install'

dmgr_profile 'Dmgr01' do
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end

# create additional Custom Node to use in cluster
websphere_profile 'CustomNode01' do
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :federate]
end

websphere_profile 'AppServer12' do
  admin_user 'admin'
  admin_password 'admin'
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['nodeRestartState', 'RUNNING']]"
      }
    }
  })
  action [:create, :federate]
end

websphere_profile 'AppServer13' do
  admin_user 'admin'
  admin_password 'admin'
  java_sdk '1.6_64'
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['maximumStartupAttempts', '3'], ['pingTimeout', '99'], ['pingInterval', '666'], ['autoRestart', 'false'], ['nodeRestartState', 'RUNNING']]"
      },
      'jvmEntries' => {
        'newvalue' => "[['debugMode', 'true']]"
      }
    }
  })
  action [:create, :federate]
end

# # deploy an application on the managed appserver, start it and stop it. start it again.
# websphere_app 'sample_app' do
#   app_file '/tmp/sample.war'
#   server_name 'AppServer12_server'
#   node_name 'AppServer12_node'
#   websphere_root '/opt/IBM/websphere/server'
#   admin_user 'admin'
#   admin_password 'admin'
#   action [:deploy_to_server, :start]
# end
