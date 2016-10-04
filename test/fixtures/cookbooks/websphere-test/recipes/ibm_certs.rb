
install_mgr 'ibm-im install' do
  install_package 'https://s3-eu-west-1.amazonaws.com/jsidentity/media/agent.installer.linux.gtk.x86_64_1.8.4000.20151125_0201.zip'
  install_package_sha256 '28f5279abc28695c0b99ae0c3fdee26bfec131186f2ca7e41d1317e303adb12e'
  package_name 'com.ibm.cic.agent'
  ibm_root_dir '/opt/IBM'
  service_user 'ibm-im'
  service_group 'ibm-im'
end

ibm_secure_storage_file '/root/MySecureStorageFile' do
  master_pw_file '/root/MyMasterPassFile'
  master_pw 'mypassphrase'
  passport_advantage true
  username node['websphere-test']['passport_advantage']['user']
  password node['websphere-test']['passport_advantage']['password']
  sensitive_exec false
end

ibm_package 'PLG Plugins install' do
  package 'com.ibm.websphere.PLG.v85,core.feature,com.ibm.jre.6_64bit'
  install_dir '/opt/IBM/WebSphere/Plugins'
  #repositories ['/opt/ibm-media/WASND_SUPPL']
  repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.PLG.v85']
  properties ({
    'eclipseLocation' => '/opt/ibm/WebSphere/Plugins',
    'user.import.profile' => 'false',
    'cic.selector.nl' => 'en'
  })
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
  action :install
  sensitive_exec false
end

user 'jim'

ibm_cert 'mydomain.com' do
  dn 'CN=mydomain.com,O=MyOrg,C=UK'
  kdb '/root/keystores/keystore.kdb'
  kdb_password 'dummy'
  algorithm 'SHA256WithRSA'
  size '2048'
  expire '10'
  owned_by 'jim'
  sensitive_exec false
  ikeycmd '/opt/IBM/WebSphere/Plugins/java/jre/bin/ikeycmd'
  action [:create, :extract]
end

cookbook_file '/root/keystores/cert_to_import.cer' do
  source 'myotherdomain.cert'
end

ibm_cert 'myotherdomain.com' do
  kdb '/root/keystores/keystore.kdb'
  kdb_password 'dummy'
  add_cert '/root/keystores/cert_to_import.cer'
  sensitive_exec false
  ikeycmd '/opt/IBM/WebSphere/Plugins/java/jre/bin/ikeycmd'
  action :add
end
