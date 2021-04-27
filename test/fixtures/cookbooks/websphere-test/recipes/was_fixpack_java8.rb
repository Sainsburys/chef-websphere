
ibm_secure_storage_file '/root/MySecureStorageFile' do
  master_pw_file '/root/MyMasterPassFile'
  master_pw 'mypassphrase'
  passport_advantage true
  username node['websphere-test']['passport_advantage']['user']
  password node['websphere-test']['passport_advantage']['password']
  sensitive_exec false
end

ibm_fixpack 'WAS ND Fixpack 14' do
  package node['websphere-test']['fixpack_package']
  install_dir '/opt/IBM/WebSphere/AppServer'
  repositories [node['websphere-test']['fixpack_repo']]
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
  action :install
end

# see https://www.ibm.com/support/knowledgecenter/en/SSAW57_8.5.5/com.ibm.websphere.installation.nd.doc/ae/cins_repositories.html
# for repository locations
ibm_package 'IBM Java 8.0' do
  package node['websphere-test']['java_package']
  install_dir '/opt/IBM/WebSphere/AppServer'
  repositories ['http://www.ibm.com/software/repositorymanager/com.ibm.websphere.IBMJAVA.v80']
  master_pw_file '/root/MyMasterPassFile'
  secure_storage_file '/root/MySecureStorageFile'
  sensitive_exec false
  action :install
end
