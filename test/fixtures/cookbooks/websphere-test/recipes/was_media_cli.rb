
# download and extract was_nd install media from s3.
include_recipe 'python'
python_pip 'awscli'

chef_gem 'aws-sdk' do
  version '~> 2.2'
  compile_time true
  action :install
end

directory node['websphere-test']['unzip_dir'] do
  recursive true
end

execute 'download was media from s3' do
  command "/usr/bin/aws s3 sync #{node['websphere-test']['was_s3_bucket']} #{node['websphere-test']['unzip_dir']}"
end

package 'unzip'
execute 'unzip was media' do
  cwd node['websphere-test']['unzip_dir']
  command "unzip -n \\*.zip -d #{node['websphere-test']['unzip_dir']}/"
end
