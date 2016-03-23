# Websphere Cookbook

## Scope

**NOTE: This cookbook is still in Beta.**

This cookbook configures Websphere Application Server Network Deployment (WAS-ND). It has only been tested with a Deployment Manager and Managed nodes.

So far it has only been tested with Websphere ND 8.5

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
    install_dir '/opt/IBM/Websphere/AppServer'
    repositories ['/my/path/to/local/install/media']
    action :install
  end
  ```

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
    install_dir '/opt/IBM/Websphere/AppServer'
    repositories ['/my/path/to/local/install/media']
    action :install
  end
  ```


### websphere_base

Do not use this directly it can be ignored. This resource is only used as a parent class for shared properties and methods for the other resources.


### websphere_dmgr

##### Example
```ruby
websphere_dmgr 'Dmgr01' do
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
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

##### Actions

- `:create` - Creates the dmgr
- `:start` - Starts the dmgr.
- `:stop` - Stops the dmgr.
- `:delete` - deletes dmgr.
˜˜

### websphere_profiles

##### Example
```ruby
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
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
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
- `profile_type`, String, default: 'appserver', Can be either appserver or custom.  Other types may be supported in the future.
- `attributes`, [Hash, nil], default: nil, These are custom attributes for the server, such as monitoringPolicy. They are only set when the node is federated.

##### Actions

- `:create` - Creates the profile
- `:federate` - Adds the node to a deployment manager for federation/management.
- `:start` - Starts the node.
- `:stop` - Stops the node.
- `:delete` - deletes node and profile and any servers on it.


### websphere_cluster

Creates an empty cluster for application servers to be added to.
>>>>>>> a4ec2bb6a4f6e50546957f3f67175976f6c9c5ee

##### Example
```ruby
websphere_cluster 'MyCluster' do
  admin_user 'admin'
  admin_password 'admin'
  action [:create]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
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

### websphere_base

Do not use this directly it can be ignored. This resource is only used as a parent class for shared properties and methods for the other resources.


### websphere_dmgr

##### Example
```ruby
<<<<<<< HEAD
websphere_dmgr 'Dmgr01' do
  cell_name 'MyNewCell'
  admin_user 'admin'
  admin_password 'admin'
  action [:create, :start]
end
```

##### Parameters

=======
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
```

##### Parameters

>>>>>>> a4ec2bb6a4f6e50546957f3f67175976f6c9c5ee
- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
<<<<<<< HEAD
- `profile_name`, String, name_property: true
- `node_name`, String, default: lazy { "#{profile_name}_node" }
- `server_name`, String, default: lazy { "#{profile_name}_server" }
- `cell_name`, [String, nil], default: nil
- `java_sdk`, [String, nil], default: nil # The javasdk version must be already be installed using ibm-installmgr cookbook. If none is specified the embedded default is used

##### Actions

- `:create` - Creates the dmgr
- `:start` - Starts the dmgr.
- `:stop` - Stops the dmgr.
- `:delete` - deletes dmgr.
˜˜

### websphere_profiles

##### Example
```ruby
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
=======
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
>>>>>>> a4ec2bb6a4f6e50546957f3f67175976f6c9c5ee
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
<<<<<<< HEAD
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
- `profile_name`, String, name_property: true
- `node_name`, String, default: lazy { "#{profile_name}_node" }
- `server_name`, String, default: lazy { "#{profile_name}_server" }
- `cell_name`, [String, nil], default: nil
- `java_sdk`, [String, nil], default: nil # The javasdk version must be already be installed using ibm-installmgr cookbook. If none is specified the embedded default is used
- `profile_type`, String, default: 'appserver', Can be either appserver or custom.  Other types may be supported in the future.
- `attributes`, [Hash, nil], default: nil, These are custom attributes for the server, such as monitoringPolicy. They are only set when the node is federated.

##### Actions

- `:create` - Creates the profile
- `:federate` - Adds the node to a deployment manager for federation/management.
- `:start` - Starts the node.
- `:stop` - Stops the node.
- `:delete` - deletes node and profile and any servers on it.


### websphere_cluster

Creates an empty cluster for application servers to be added to.

##### Example
```ruby
websphere_cluster 'MyCluster' do
  admin_user 'admin'
  admin_password 'admin'
  action [:create]
end
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
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
```

##### Parameters

- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.  This should only be known to people who know the server is managed with chef.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
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

- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
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

Deploys an ihs webserver to an existing profile/node.

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

=======
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

Deploys an ihs webserver to an existing profile/node.

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

>>>>>>> a4ec2bb6a4f6e50546957f3f67175976f6c9c5ee
- `websphere_root`, String, default: '/opt/IBM/Websphere/AppServer', The was install root
- `bin_dir`, String, default: lazy { "#{websphere_root}/bin" } The path to the was root bin directory. No need to change this.
- `admin_user`, [String, nil], default: nil, The dmgr user.  
- `admin_password`, [String, nil], default: nil, The dmgr password.
- `dmgr_host`, String, default: 'localhost', The dmgr host to federate to.
- `dmgr_port`, [String, nil], default: nil, The dmgr port to federate to.
- `webserver_name`, String, name_property: true
- `plg_root`, String, default: '/opt/IBM/Websphere/Plugins'
- `wct_root`, String, default: '/opt/IBM/Websphere/Toolbox'
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
