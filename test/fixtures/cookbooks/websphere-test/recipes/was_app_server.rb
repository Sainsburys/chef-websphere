include_recipe 'websphere-test::was_install_small'

websphere_dmgr 'Dmgr01' do
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end

websphere_profile 'Custom' do
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
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
        'newvalue' => "[['debugMode', 'true']]"
      }
    }
  })
  action [:create, :start]
end

websphere_app_server 'app_server2' do
  server_node 'Custom_node'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start, :delete]
end
