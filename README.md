# Websphere Cookbook

## Scope

**NOTE: This cookbook is still in Beta.**

This cookbook installs and configures Websphere Application Server Network Deployment (WAS-ND). It has only been tested with a Deployment Manager and Managed nodes.

So far it has only been tested with Websphere ND 8.5.

The cookbook lacks idempotency as querying WAS for the current state is overly complex, really slow, or just not possible.  For that reason it's better to destroy and recreate objects rather than update them at this stage.

## Requirements
* Chef 12.5 or higher
* Installation media for Installation manager either local or via a url, and Media or repositories for any other packages like WAS ND, IHS etc.
* You will first need to install Websphere Network Deployment version using the ibm-installmgr cookbook.  See test/fixtures/cookbooks/webshpere-test/recipes/was_install.rb for an example.

## Platform
* Centos 6
* Red Hat Enterprise 6

## Versions
• WASND 8.5

## Usage

The general pattern for usage is to:
1. Instal Installation Manager with the installation manager cookbook
2. Install Websphere ND, Websphere Toolbox and Websphere Plugins (for IHS)
2. Deploy a Dmgr
3. Deploy a custom profile
4. Deploy an appserver OR Deploy a cluster and add a cluster member to the profile
5. Deploy IHS if needed.

### Install

You first need to install the necessary components. To do this use the ibm-installmgr cookbook.  It can be used to install any of the following:
  - Websphere ND
  - Any Websphere ND Fixpacks
  - IBM Java version(s)
  - Websphere Plugins (PLG)
  - Websphere customization toolbox
  - IHS HTTP Server.

As well as the below example, see test/fixtures/cookbooks/webshpere-test/recipes/was_install.rb for a more complete example.

##### Example
  ```ruby
  install_mgr 'ibm-im install' do
    install_package 'https://someurl/agent.installer.linux.gtk.x86_64_1.8.4000.20151125_0201.zip'
    install_package_sha256 '28f5279abc28695c0b99ae0c3fdee26bfec131186f2ca7e41d1317e303adb12e'
    package_name 'com.ibm.cic.agent'
    ibm_root_dir '/opt/IBM'
    service_user 'ibm-im'
    service_group 'ibm-im'
  end

  ibm_package 'WAS ND install' do
    package 'com.ibm.websphere.ND.v85'
    install_dir '/opt/IBM/WebSphere/AppServer'
    repositories ['/my/path/to/local/install/media']
    action :install
  end
  ```


### websphere_base

Do not use this directly it can be ignored. This resource is only used as a parent class to share methods between child resources.

### websphere_dmgr

##### Example
```ruby
websphere_dmgr 'Dmgr01' do
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'mypassword'
  action [:create, :start]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/WebSphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host/ip.
- `dmgr_port`, [String, nil], default: nil, The dmgr port, when nil WAS will default to dmgr SOAP connector default port 8879.
- `profile_name`, String, name_property: true. # The Dmgr profile name.
- `node_name`, String, default: lazy { "#{profile_name}_node" }. It's easier to keep the default name here.
- `server_name`, String, default: lazy { "#{profile_name}_server" } It's easier to keep the default name here.
- `cell_name`, [String, nil], default: nil
- `java_sdk`, [String, nil], default: nil # The javasdk version must be already be installed using ibm-installmgr cookbook. If none is specified the embedded default is used
- `security_attributes`, [Hash, nil], default: nil # A hash of security attributes to apply to the dmgr

##### Actions

- `:create` - Creates the dmgr
- `:start` - Starts the dmgr.
- `:stop` - Stops the dmgr.
- `:sync_all` - Syncs all federated nodes in the dmgr without restarting the appservers

### websphere_profiles

This resource currently only allows for appserver or custom profiles. It's best to use custom resources everywhere, and add appservers to it later with the websphere_app_server or websphere_cluster_member resources.


##### Example
```ruby
websphere_profile 'AppProfile1' do
  admin_user 'admin'
  admin_password 'admin'
  dmgr_host 'localhost'
  action [:create, :federate, :start]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/WebSphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
- `profile_name`, String, name_property: true
- `node_name`, String, default: lazy { "#{profile_name}_node" }
- `server_name`, String, default: lazy { "#{profile_name}_server" }
- `cell_name`, [String, nil], default: nil
- `java_sdk`, [String, nil], default: nil # The javasdk version must be already be installed using ibm-installmgr cookbook. If none is specified the embedded default is used
- `profile_type`, String, default: 'custom', Can be either appserver or custom, but easier to just use custom all the time and add jvms with websphere_app_server or websphere_cluster_member.
- `attributes`, [Hash, nil], default: nil, These are custom attributes for the server when using the appserver type profile, such as monitoringPolicy. They are only set when the node is federated.

##### Actions

- `:create` - Creates the profile
- `:federate` - Adds the node to a deployment manager for federation/management.
- `:start` - Starts the node.
- `:stop` - Stops the node.
- `:delete` - deletes node and profile and any servers on it. You need to delete any clusters before you can delete the node.

### websphere_app_server

Adds a new jvm to an existing custom profile

##### Example
```ruby
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
        'newvalue' => "[['debugMode', 'true'], ['systemProperties',[[['name','my_custom_websphere_variable'],['value','testing2']]]]]"
      }
    }
  })
  action [:create, :start]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/WebSphere/AppServer', The was install root.
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host.
- `dmgr_port`, [String, nil], default: nil, The dmgr port leave as nil for default 8879.
- `server_name`, String, name_property: true, The new clustered server name
- `server_node`, [String, nil], default: nil, required: true, The node to create the server on.
- `attributes`, [Hash, nil], default: nil, A hash of attributes to apply to the server, eg. monitoringPolicy.

##### Actions

- `:create` - Creates the server on node
- `:delete` - Deletes the server
- `:start` - Starts the server

### websphere_cluster

Creates an empty cluster to add app servers to.

##### Example
```ruby
websphere_cluster 'MyCluster' do
  admin_user 'admin'
  admin_password 'admin'
  dmgr_host 'localhost'
  action [:create]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/WebSphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
- `cluster_name`, String, name_property: true
- `prefer_local`, [TrueClass, FalseClass], default: true

##### Actions

- `:create` - Creates the cluster
- `:delete` - Deletes the cluster
- `:start` - Starts the servers on the cluster.
- `:ripple_start` - Ripple starts servers on the cluster.


### websphere_cluster_member

Creates and adds an application server to a cluster

##### Example
```ruby
websphere_cluster_member 'ClusterServer1' do
  cluster_name 'MyCluster'
  server_node 'CustomProfile1_Node'
  admin_user 'admin'
  admin_password 'admin'
  member_weight 15
  attributes ({
    'processDefinitions' => {
      'monitoringPolicy' => {
        'newvalue' => "[['maximumStartupAttempts', '2'], ['pingInterval', '222'], ['autoRestart', 'true'], ['nodeRestartState', 'PREVIOUS']]"
      },
      'jvmEntries' => {
        'newvalue' => "[['debugMode', 'true'], ['systemProperties',[[['name','my_custom_websphere_variable'],['value','testing2']]]]]"
      }
    }
  })
  action [:create, :start]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/WebSphere/AppServer', The was install root.
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host.
- `dmgr_port`, [String, nil], default: nil, The dmgr port leave as nil for default 8879.
- `cluster_name`, String
- `prefer_local`, [TrueClass, FalseClass], default: true
- `server_name`, String, name_property: true, The new clustered server name
- `server_node`, [String, nil], default: nil, required: true, The node to create the server on.
- `member_weight`, Fixnum, default: 2 # number from 0-100. Higher weight gets more traffic
- `session_replication`, [TrueClass, FalseClass], default: false
- `resources_scope`, String, default: 'both', regex: /^(both|server|cluster)$/
- `attributes`, [Hash, nil], default: nil, A hash of attributes to apply to the server, eg. monitoringPolicy.

##### Actions

- `:create` - Creates the server and adds to cluster
- `:delete` - Deletes the server
- `:start` - Starts the server


### websphere_app

Deploys an application to a server or cluster

##### Example
```ruby
websphere_app 'sample_app_cluster' do
  app_file '/tmp/sample.war'
  cluster_name 'MyCluster'
  admin_user 'admin'
  admin_password 'admin'
  action [:deploy_to_cluster, :start, :stop]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/WebSphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
- `app_name`, String, name_property: true
- `app_file`, [String, nil], default: nil, required: true
- `server_name`, [String, nil], default: nil
- `node_name`, [String, nil], default: nil
- `cluster_name`, [String, nil], default: nil
- `context_root`, [String, nil], default: nil

##### Actions

- `:deploy_to_cluster` - Deploys app to a cluster
- `:deploy_to_server` - Deploys app to a server
- `:start` - Starts the app
- `:stop` - Stops the app


### websphere_ihs

Deploys an ihs webserver to an existing profile/node.  It currently only supports managed ihs webservers.

##### Example
```ruby
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
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/WebSphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
- `webserver_name`, String, name_property: true
- `plg_root`, String, default: '/opt/IBM/WebSphere/Plugins'
- `wct_root`, String, default: '/opt/IBM/WebSphere/Toolbox'
- `wct_tool_root`, String, default: lazy { "#{wct_root}/WCT" }
- `config_type`, String, default: 'local_distributed', Can only be local_distributed or remote.
- `profile_name`, String, required: true
- `node_name`, String, required: true
- `map_to_apps`, [TrueClass, FalseClass], default: false
- `ihs_hostname`, [String],  default: lazy { node.name }
- `ihs_port`, String, default: '80'
- `ihs_install_root`, default: '/opt/IBM/HTTPServer'
- `ihs_config_file`, String, default: lazy { "#{ihs_install_root}/conf/httpd.conf" }
- `runas_user`, String, default: 'root'
- `runas_group`, String, default: 'root'
- `enable_ihs_admin_server`, [TrueClass, FalseClass], default: false
- `ihs_admin_user`, [String, nil], default: nil
- `ihs_admin_password`, [String, nil], default: nil
- `ihs_admin_port`, String, default: '8008'

##### Actions

- `:create` - Creates a web definition and deploys a webserver
- `:delete` - deletes the web definition
- `:start` - starts the webserver
- `:stop` - stops the webserver


### ibm_cert

Used to manage ibm java certificates.  Create keystore, create certificates and add to keystore, add existing certs to keystore. extract cert from keystore.

This can be used on any server with ikeycmd tool.

##### Example
```ruby
ibm_cert 'mydomain.com' do
  dn 'CN=mydomain.com,O=MyOrg,C=UK'
  kdb '/root/keystores/keystore.kdb'
  kdb_password 'dummy'
  algorithm 'SHA256WithRSA'
  size '2048'
  expire '10'
  owned_by 'jim'
  action [:create, :extract]
end

ibm_cert 'myotherdomain.com' do
  kdb '/root/keystores/keystore.kdb'
  kdb_password 'dummy'
  add_cert '/root/keystores/cert_to_import.cer'
  action :add
end
```

##### Parameters

- label, String, name_property: true
- dn, String, required: true eg "CN=mydomain.com,O=MyOrg,C=UK"
- kdb, String, required: true, regex: Path to keystore file. Will create if it doesn't exist. File must end in .kdb or .p12
- kdb_password, String, required: true
- algorithm, String, default: 'SHA256WithRSA'
- size, String, default: '2048', Can be 2048, 1024 or 512
- expire, String, default: '3600', required: true
- extract_to, String, Used by the extract action only. Extracts in ASCII to a file <label>.cer next to the keystore file location by default. #{label}.cer" } .
- add_cert, [String, nil], default: nil  path to certificate to add to keystore, only used in add.
- default_cert, String, default: 'no'. Can be yes or no
- ikeycmd, String, default: /opt/IBM/WebSphere/AppServer/java/jre/bin/ikeycmd path to ikeycmd tool.
- owned_by, String, default: 'root'
- sensitive_exec, [TrueClass, FalseClass], default: true # for debug purposes only.

##### Actions

- `:create` - Creates a keystore with a default certificate
- `:extract` - extracts a certificate from a keystore
- `:add` - adds an existing certificate to an existing keystore.


### websphere_env

Creates a websphere environment variable

##### Example

```ruby
websphere_env 'TESTING_1234' do
  scope 'Cell=Cell1'
  value '/some/value'
  admin_user 'admin'
  admin_password 'admin'
  action :set
end
```
##### Parameters

- `variable_name`, [String, nil], name_property.
- `scope`, String, required: true. eg Cell=Cell1
- `value`, [String, nil], default: nil

##### Actions

- `:set` - creates the variable and sets the value.
- `:remove` - removes the variable.


### websphere_jms_provider

Creates a custom jms provder in websphere

##### Example

```ruby
websphere_jms_provider 'ActiveMQ' do
  scope 'Cell=Cell1'
  context_factory 'org.apache.activemq.jndi.ActiveMQWASInitialContextFactory'
  url 'nsps://devtlnx0287.stbc2.jstest2.net:15071;nsps://devtlnx0293.stbc2.jstest2.net:15071'
  classpath_jars ['/drivers/nClient-9.7.jar', '/drivers/nJMS-9.7.jar']
  description 'ActiveMQ JMS Provider created by Chef'
  admin_user 'admin'
  admin_password 'admin'
  dmgr_host 'localhost'
  action [:create]
end
```

##### Parameters

- `provider_name`, String, name_property: true. Unique name for the custom provider.
- `scope`, String, required: true. eg Cell=Cell1
- `context_factory`, [String, nil], default: nil
- `url`, [String, nil], default: nil
- `classpath_jars`, [Array, nil], default: nil Full path to each jar driver
- `description`, [String, nil], default: nil


##### Actions

- `:create` - Creates a jms provider


### websphere_jms_conn_factory

Creates a jms connection factory

##### Example

```ruby
websphere_jms_conn_factory 'My Queue Conection Factory' do
  scope 'Cell=Cell1'
  jndi_name 'jms/MyQueueFactory'
  ext_jndi_name 'MyQueueFactory_external_name'
  jms_provider 'ActiveMQ'
  type 'QUEUE'
  conn_pool_timeout '220'
  admin_user 'admin'
  admin_password 'admin'
  dmgr_host 'localhost'
  action [:create]
end
```

##### Parameters

conn_factory_name, String, name_property: true
scope, String, required: true eg 'Cell=MyCell,Cluster=MyCluster'
jndi_name, String, required: true
ext_jndi_name, String, required: true
jms_provider, String, required: true
type, String, required: true, Can be only QUEUE, TOPIC or UNIFIED
description, [String, nil], default: nil
category, [String, nil], default: nil
conn_pool_timeout, String, default: '180'
conn_pool_min, String, default: '1'
conn_pool_max, String, default: '10'
conn_pool_reap_time, String, default: '180'
conn_pool_unused_timeout, String, default: '1800'
conn_aged_timeout, String, default: '0'
conn_purge_policy, String, default: 'FailingConnectionOnly' can be only FailingConnectionOnly or EntirePool

##### Actions

- `:create` - Creates a jms conection factory


### websphere_jms_destination

Creates a jms queue or topic

##### Example

```ruby
websphere_jms_destination 'My Queue' do
  jndi_name 'myQueue'
  ext_jndi_name 'jms/myQueue'
  scope 'Cell=Cell1'
  jms_provider 'ActiveMQ'
  type 'QUEUE'
  admin_user 'admin'
  admin_password 'admin'
  dmgr_host 'localhost'
  action [:create]
end
```

##### Parameters

jms_dest_name, String, name_property: true
jndi_name, String, required: true
ext_jndi_name, String, required: true
scope, String, required: true eg 'Cell=MyCell,Cluster=MyCluster'
jms_provider, String, required: true
type, String, required: true, Can be QUEUE, TOPIC or UNIFIED
description, [String, nil], default: nil
category, [String, nil], default: nil


##### Actions

- `:create` - Creates a jms queue or topic


### websphere_wsadmin

A wrapper around the wsadmin command. Added for convenience to perform tasks that are not yet available as resources in this cookbook.

```ruby
websphere_wsadmin 'do some wsadmin' do
  admin_user secrets['ibm_was']['dmgr_user']
  admin_password secrets['ibm_was']['dmgr_pw']
  file "myscript.py paramforscript"
  dmgr_host 'localhost'
  action [:run, :save]
end

websphere_wsadmin 'do some more wsadmin' do
  admin_user secrets['ibm_was']['dmgr_user']
  admin_password secrets['ibm_was']['dmgr_pw']
  script "AdminServerManagement.stopSingleServer('mynode', 'myserver')"
  dmgr_host 'localhost'
  action :run
end
```

##### Parameters

label, String, name_property: true just a label to make the execute resource name unique
script, [String, nil], default: nil. The command for wsadmin to run.  If a file is given this will be ignored, and only the file will be executed.
file, [String, nil], default: nil The script file for wsadmin to run.
return_codes, Array, default: [0]. Return codes to allow.
sensitive, [TrueClass, FalseClass], default: false. For security to hide passwords form output if necessary.


## License and Author

* Authors: Lachlan Munro (<lachlan.munro@sainsburys.co.uk>), Chris Bell (<chris.bell@sainsburys.co.uk>)


Copyright: 2016, J Sainsburys

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
