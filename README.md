# Websphere Cookbook

## Scope
This cookbook configures Websphere Application Server (WAS) cells profiles, nodes, appservers, clusters and web servers. It has been tested using a distributed environment using a deployment manager for management. It has NOT been tested using standalone//unmanaged nodes and app servers.

You will first need to install websphere using the ibm_installmgr cookbook (See Usage and embedded test cookbook for examples)
It has only been tested with Websphere ND 8.5

## Requirements
* Chef 12.5 or higher
* Installation Media for Installation manager either local or via a url, and Media or repositories for any other packages like WAS ND, IHS etc.
* You will need to install Websphere Network Deployment version using the ibm_installmgr cookbook.  See test/fixtures/cookbooks/webshpere-test/recipes/was_install.rb for an example.

## Platform
* Centos 6
* Red Hat Enterprise 6

## Usage

### Resources

### websphere_profile

Creates a Websphere profile of type appserver or custom.


##### Example
```ruby
websphere_profile 'Deployment Manager' do

end
```

##### Parameters

- `profile_type` String, required: true, default: nil, Must be one of: appserver|custom|cell|deploymgr|proxy|job The admin profile is not supported as you managed the appserver through Chef.
- `websphere_root` String, default: '/opt/ibm/Websphere/server/'
- `profile_path` String, default: lazy { "#{websphere_root}/profiles" }
- `manage_profiles_sh` String, default: lazy { "#{websphere_root}/bin/manageprofiles.sh" }
- `admin_user` String, default: nil  Applies to all profiles except custom profile.
- `admin_password` String, default: nil.
- `ports_allocation` String, default: recommended. Must be one of: default|recommended|file . If you choose file you must set the ports_file parameter. File is not currently working.
- `ports_file` String, default: nil This is not yet working. Path to a ports file.
- ``

##### Actions

- `:create` - Creates or Updates profile

- `:start` - Starts a profile.

- `:delete` - deletes profile



## License and Author

* Author: Dan Webb (<d.webb@derby.ac.uk>)

Copyright: 2015, J Sainsburys

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
