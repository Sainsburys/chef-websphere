
# download and extract was_nd install media from s3.
[
  node['websphere-test']['unzip_dir'],
  node['websphere-test']['agent_unzip_dir'],
  node['websphere-test']['suppl_unzip_dir'],
  node['websphere-test']['fixpack_repo'],
].each do |dir|
  directory dir do
    recursive true
  end
end

# Installer Agent
agent_split_array = node['websphere-test']['agent_s3_zip'].split('/') # need to split the s3 path bucket/path_to_file to use in resource.

aws_s3_file "#{node['websphere-test']['agent_unzip_dir']}/#{agent_split_array.last}" do
  bucket agent_split_array.first
  remote_path agent_split_array[1..-1].join('/')
  use_etag false
  use_last_modified true
  action :create_if_missing
end

# WASND Media
split_array = node['websphere-test']['s3_zip'].split('/') # need to split the s3 path bucket/path_to_file to use in resource.

aws_s3_file node['websphere-test']['zip_file'] do
  bucket split_array.first
  remote_path split_array[1..-1].join('/')
  use_etag false
  use_last_modified true
  action :create_if_missing
end

package 'unzip'
execute 'unzip WASND media' do
  command "unzip -o #{node['websphere-test']['zip_file']} -d #{node['websphere-test']['unzip_dir']}"
  not_if { ::File.exist?("#{node['websphere-test']['repo_dir']}/repository.config") }
end

# WASND_SUPPL Media
split_array = node['websphere-test']['suppl_s3_zip'].split('/') # need to split the s3 path bucket/path_to_file to use in resource.
aws_s3_file node['websphere-test']['suppl_zip_file'] do
  bucket split_array.first
  remote_path split_array[1..-1].join('/')
  use_etag false
  use_last_modified true
  action :create_if_missing
end

execute 'unzip WASND_SUPPL media' do
  command "unzip -o #{node['websphere-test']['suppl_zip_file']} -d #{node['websphere-test']['suppl_unzip_dir']}"
  not_if { ::File.exist?("#{node['websphere-test']['suppl_repo']}/repository.config") }
end

# WASND FixPack Media
split_array = node['websphere-test']['fixpack_s3_zip'].split('/') # need to split the s3 path bucket/path_to_file to use in resource.
aws_s3_file node['websphere-test']['fixpack_zip_file'] do
  bucket split_array.first
  remote_path split_array[1..-1].join('/')
  use_etag false
  use_last_modified true
  action :create_if_missing
end

execute 'unzip WASND FixPack media' do
  command "unzip -o #{node['websphere-test']['fixpack_zip_file']} -d #{node['websphere-test']['fixpack_repo']}"
  not_if { ::File.exist?("#{node['websphere-test']['fixpack_repo']}/repository.config") }
end
