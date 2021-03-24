name 'websphere'
maintainer 'J Sainsburys Plc.'
maintainer_email 'GOL.CloudEngineering@sainsburys.co.uk'
license 'Apache-2.0'
description 'Installs/Configures IBM WebSphere'
version '1.2.1'
supports 'redhat'
supports 'centos'

depends 'ibm-installmgr'

source_url 'https://github.com/sainsburys/websphere'
issues_url 'https://github.com/sainsburys/websphere/issues'
chef_version '>= 12.5' if respond_to?(:chef_version)
