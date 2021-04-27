
include_recipe 'websphere-test::was_install_basic'

websphere_dmgr 'Dmgr01 create' do
  profile_name 'Dmgr01'
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end

websphere_jms_provider 'WebMethodsUMProvider' do
  scope 'Cell=MyNewCell'
  context_factory 'com.pcbsys.nirvana.nSpace.NirvanaContextFactory'
  url 'nsps://mydomain:15103'
  classpath_jars ['/app/somejar.jar']
  description 'A pretend Universal Messaging WebSphere JMS Provider'
  admin_user 'admin'
  admin_password 'admin'
  action [:create]
end

websphere_jms_destination 'My Queue' do
  jndi_name 'myQueue'
  ext_jndi_name 'jms/myQueue'
  scope 'Cell=MyNewCell'
  jms_provider 'WebMethodsUMProvider'
  type 'QUEUE'
  admin_user 'admin'
  admin_password 'admin'
  action [:create]
end

websphere_jms_conn_factory 'My Queue Conection Factory' do
  scope 'Cell=MyNewCell'
  jndi_name 'MyQueueFactory'
  ext_jndi_name 'jms/MyQueueFactory'
  jms_provider 'WebMethodsUMProvider'
  type 'QUEUE'
  conn_pool_timeout '220'
  admin_user 'admin'
  admin_password 'admin'
  action [:create]
end

websphere_env 'TESTING_1234' do
  scope 'Cell=MyNewCell'
  value '/some/value'
  admin_user 'admin'
  admin_password 'admin'
  action :set
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
