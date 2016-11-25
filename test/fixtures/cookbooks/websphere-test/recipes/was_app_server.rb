include_recipe 'websphere-test::was_install_basic'

websphere_dmgr 'Dmgr01' do
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:create, :start]
end

websphere_profile 'Custom' do
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:create, :federate]
end

websphere_app_server 'app_server1' do
  node_name 'Custom_node'
  admin_user 'admin'
  admin_password 'admin'
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
  sensitive_exec false
  action [:create, :start]
end

websphere_app_server 'app_server2' do
  node_name 'Custom_node'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:create, :start, :delete]
end

remote_file '/tmp/sample.war' do
  source 'https://s3-eu-west-1.amazonaws.com/jsidentity/was_sample_apps/sample.war'
  mode '0755'
  action :create
end

# deploy an unclustered application on the managed appserver
# start it and stop it. start it again.
websphere_app 'sample_app' do
  app_file '/tmp/sample.war'
  server_name 'app_server1'
  node_name 'Custom_node'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:deploy_to_server, :start]
end

log 'test restarting app' do
  message 'test restarting app'
  level :info
  notifies :stop, 'websphere_app[sample_app]', :immediately
  notifies :start, 'websphere_app[sample_app]', :immediately
end

websphere_profile 'App_Profile' do
  profile_type 'appserver'
  server_name 'AppProfile_server'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:create, :federate, :start]
end
