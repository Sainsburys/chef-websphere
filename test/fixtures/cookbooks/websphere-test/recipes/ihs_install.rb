
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

ibm_secure_storage_file '/root/MySecureStorageFile' do
  master_pw_file '/root/MyMasterPassFile'
  master_pw 'mypassphrase'
  passport_advantage true
  username node['websphere-test']['passport_advantage']['user']
  password node['websphere-test']['passport_advantage']['password']
  sensitive_exec true
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
