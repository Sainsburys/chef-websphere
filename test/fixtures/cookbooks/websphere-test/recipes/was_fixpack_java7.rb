
ibm_secure_storage_file '/root/MySecureStorageFile' do
  master_pw_file '/root/MyMasterPassFile'
  master_pw 'mypassphrase'
  passport_advantage true
  username node['websphere-test']['passport_advantage']['user']
  password node['websphere-test']['passport_advantage']['password']
  sensitive_exec false
end

ibm_fixpack 'WAS ND Fixpack 10' do
  package 'com.ibm.websphere.ND.v85_8.5.5010.20160721_0036,core.feature,ejbdeploy,thinclient,embeddablecontainer,com.ibm.sdk.6_64bit'
  install_dir '/opt/IBM/WebSphere/AppServer'
  repositories [node['websphere-test']['fixpack_repo']]
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
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

ibm_package 'IBM Java 7.1' do
  # package 'com.ibm.websphere.IBMJAVA.v71_7.1.3010.20151112_0058'
  package 'com.ibm.websphere.IBMJAVA.v71_7.1.3040.20160720_1746'
  install_dir '/opt/IBM/WebSphere/AppServer'
  repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.IBMJAVA.v71']
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
  sensitive_exec false
  action :install
end
