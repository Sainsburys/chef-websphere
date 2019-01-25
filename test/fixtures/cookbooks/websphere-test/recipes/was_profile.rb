include_recipe 'websphere-test::was_install_basic'

websphere_dmgr 'Dmgr01 create' do
  profile_name 'Dmgr01'
  cell_name 'MyNewCell'
  node_name 'MyNewNode'
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
  timeout node['websphere-test']['profile_timeout']
  action [:create, :federate, :start]
end
