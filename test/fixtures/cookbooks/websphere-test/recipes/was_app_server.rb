include_recipe 'websphere-test::was_install_basic'

websphere_dmgr 'Dmgr01 create' do
  profile_name 'Dmgr01'
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:create, :start]
end

websphere_profile 'Custom profile create and federate' do
  profile_name 'Custom'
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
  # rubocop:disable Lint/ParenthesesAsGroupedExpression
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['maximumStartupAttempts', '2'], ['pingInterval', '222'], ['autoRestart', 'true'], ['nodeRestartState', 'PREVIOUS']]",
      },
      'jvmEntries' => {
        'newvalue' => "[['debugMode', 'true'], ['initialHeapSize', 1024], ['maximumHeapSize', 3072], ['systemProperties',[[['name','my_system_property'],['value','testing123']]]]]",
      },
    },
  })
  # rubocop:enable Lint/ParenthesesAsGroupedExpression
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

remote_file File.join(Chef::Config[:file_cache_path], 'sample.war') do
  source 'https://s3-eu-west-1.amazonaws.com/jsidentity/was_sample_apps/sample.war'
  mode '0755'
  action :create
end

# deploy an unclustered application on the managed appserver
# start it and stop it. start it again.
websphere_app 'sample_app' do
  app_file File.join(Chef::Config[:file_cache_path], 'sample.war')
  server_name 'app_server1'
  node_name 'Custom_node'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:deploy_to_server, :start]
  notifies :run, 'notify_group[test restarting app]', :immediately
end

notify_group 'test restarting app' do
  notifies :stop, 'websphere_app[sample_app]', :immediately
  notifies :start, 'websphere_app[sample_app]', :immediately
end

websphere_profile 'App_Profile create/federate/start' do
  profile_name 'App_Profile'
  profile_type 'appserver'
  server_name 'AppProfile_server'
  admin_user 'admin'
  admin_password 'admin'
  sensitive_exec false
  action [:create, :federate, :start]
end
