name 'websphere'
maintainer 'JS Sainsburys'
maintainer_email 'lachlan.munro@sainsburys.co.uk'
license 'Apache 2.0'
description 'Installs/Configures IBM Websphere'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.2'
supports 'redhat'
supports 'centos'

depends 'ibm-installmgr'

source_url 'https://github.com/sainsburys/websphere'
issues_url 'https://github.com/sainsburys/websphere/issues'
chef_version '>= 12.5' if respond_to?(:chef_version)
