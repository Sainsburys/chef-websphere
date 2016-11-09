
include_recipe 'chef-sugar'
include_recipe 'websphere-test::was_media' unless vagrant?

# install for RHEL 6 based on
# http://www.ibm.com/support/knowledgecenter/SSAW57_8.5.5/com.ibm.websphere.installation.nd.doc/ae/tins_linuxsetup_rhel6.html?cp=SSAW57_8.5.5%2F1-5-0-4-2-2
package ['glibc', 'compat-libstdc++-33', 'compat-db']
include_recipe 'build-essential'

install_mgr 'ibm-im install' do
  install_package 'https://s3-eu-west-1.amazonaws.com/jsidentity/media/agent.installer.linux.gtk.x86_64_1.8.4000.20151125_0201.zip'
  install_package_sha256 '28f5279abc28695c0b99ae0c3fdee26bfec131186f2ca7e41d1317e303adb12e'
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

ibm_secure_storage_file '/root/MySecureStorageFile' do
  master_pw_file '/root/MyMasterPassFile'
  master_pw 'mypassphrase'
  passport_advantage true
  username node['websphere-test']['passport_advantage']['user']
  password node['websphere-test']['passport_advantage']['password']
  sensitive_exec false
end

ibm_fixpack 'WAS ND Fixpack 3' do
  package 'com.ibm.websphere.ND.v85_8.5.5008.20151112_0939,core.feature,ejbdeploy,thinclient,embeddablecontainer,com.ibm.sdk.6_64bit'
  install_dir '/opt/IBM/WebSphere/AppServer'
  repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.ND.v85']
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
  action :install
end

ibm_package 'IBM Java 7.1' do
  package 'com.ibm.websphere.IBMJAVA.v71_7.1.3010.20151112_0058'
  install_dir '/opt/IBM/WebSphere/AppServer'
  repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.IBMJAVA.v71']
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
  action :install
end

ibm_package 'PLG Plugins install' do
  package 'com.ibm.websphere.PLG.v85,core.feature,com.ibm.jre.6_64bit'
  # packages ['com.ibm.websphere.PLG.v85,core.feature,com.ibm.jre.6_64bit']
  install_dir '/opt/IBM/WebSphere/Plugins'
  repositories [node['websphere-test']['suppl_repo']]
  # repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.PLG.v85']
  properties ({
    'eclipseLocation' => '/opt/ibm/WebSphere/Plugins',
    'user.import.profile' => 'false',
    'cic.selector.nl' => 'en'
  })
  # master_pw_file '/root/MyMasterPassFile'
  # secure_storage_file '/root/MySecureStorageFile'
  action :install
  sensitive_exec false
end

ibm_package 'IHS install' do
  package 'com.ibm.websphere.IHS.v85,core.feature,arch.64bit'
  install_dir '/opt/IBM/HTTPServer'
  repositories [node['websphere-test']['suppl_repo']]
  properties ({
    'eclipseLocation' => '/opt/IBM/HTTPServer',
    'user.import.profile' => 'false',
    'user.ihs.httpPort' => '80',
    'user.ihs.installHttpService' => 'true',
    'user.ihs.allowNonRootSilentInstall' => 'true',
    'cic.selector.nl' => 'en'
  })
  preferences ({
    'com.ibm.cic.common.core.preferences.preserveDownloadedArtifacts' => 'true'
  })
  # repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.IHS.v85']
  # master_pw_file '/root/MyMasterPassFile'
  # secure_storage_file '/root/MySecureStorageFile'
  action :install
  sensitive_exec false
end

ibm_package 'WCT Toolbox install' do
  package 'com.ibm.websphere.WCT.v85,core.feature,pct'
  # package 'com.ibm.websphere.WCT.v85,core.feature,pct,zpmt,zmmt'
  # package 'com.ibm.websphere.WCT.v85_8.5.5000.20130514_1044'
  install_dir '/opt/IBM/WebSphere/Toolbox'
  # repositories ['/opt/ibm-media/WASND_SUPPL']
  repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.WCT.v85']
  properties ({
    'eclipseLocation' => '/opt/IBM/WebSphere/Toolbox',
    'user.import.profile' => 'false',
    'user.select.64bit.image.com.ibm.websphere.WCT.v85' => 'true',
    'cic.selector.nl' => 'en'
  })
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
  sensitive_exec false
  action :install
end
