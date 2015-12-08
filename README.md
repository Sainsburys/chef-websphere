# Websphere Cookbook

## Scope
This cookbook installs Oracle Websphere Server.
It does not install or manage any services.

## Requirements
* Chef 12 or higher
* Network accessible artifact repository

## Platform
* Centos 6
* Red Hat Enterprise 6

## Usage

### Resources
```
websphere '8.5' do
  ownername 'websphere'
  groupname 'websphere_admin'
end
```
### Attributes
```
node['common_artifact_repo'] = 'https://artifact.server/software'
```

### Common Artifact Repository
This cookbook uses a common artifact repository pattern.
Artifacts urls will be generated in the following manner:

node['common_artifact_repo'] + vendor + product + version + file_as_named_by_vendor

eg. the above resource & attribute will attempt to retrieve artifacts from the following
locations:
```
https://artifact.server/software/ibm/websphere/<version>/<jar_name>.jar
```

Artifact urls can be overridden by specifying installer_url on the
resource.

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
