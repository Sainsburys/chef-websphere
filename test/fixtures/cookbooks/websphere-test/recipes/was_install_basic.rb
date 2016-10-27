
include_recipe 'chef-sugar'
# include_recipe 'websphere-test::was_media_cli' unless vagrant?

# install for RHEL 6 based on
# http://www.ibm.com/support/knowledgecenter/SSAW57_8.5.5/com.ibm.websphere.installation.nd.doc/ae/tins_linuxsetup_rhel6.html?cp=SSAW57_8.5.5%2F1-5-0-4-2-2
package ['glibc', 'compat-libstdc++-33', 'compat-db']
include_recipe 'build-essential'

install_mgr 'ibm-im install' do
  install_package "#{node['websphere-test']['unzip_dir']}/agent.installer.linux.gtk.x86_64_1.8.4000.20151125_0201.zip"
  # install_package_sha256 '28f5279abc28695c0b99ae0c3fdee26bfec131186f2ca7e41d1317e303adb12e'
  package_name 'com.ibm.cic.agent'
  ibm_root_dir '/opt/IBM'
  service_user 'ibm-im'
  service_group 'ibm-im'
end

ibm_package 'WAS ND install' do
  package 'com.ibm.websphere.ND.v85_8.5.5000.20130514_1044,core.feature,ejbdeploy,thinclient,embeddablecontainer,com.ibm.sdk.6_64bit'
  install_dir '/opt/IBM/WebSphere/AppServer'
  repositories [node['websphere-test']['repo_dir']]
  action :install
end
