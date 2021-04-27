
include_recipe 'websphere-test::was_install_basic'
include_recipe 'websphere-test::ihs_install'

websphere_dmgr 'Dmgr01 create' do
  profile_name 'Dmgr01'
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end

# create additional Custom Node to use in cluster
websphere_profile 'Custom01 create/federate' do
  profile_name 'Custom01'
  profile_type 'custom'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :federate]
end

websphere_ihs 'MyWebserver1' do
  config_type 'local_distributed'
  profile_name 'Custom01'
  node_name 'Custom01_node'
  map_to_apps true
  ihs_port '80'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end

log 'test restarting webserver' do
  message 'test restarting webserver'
  level :info
  notifies :restart, 'websphere_ihs[MyWebserver1]', :immediately
end
