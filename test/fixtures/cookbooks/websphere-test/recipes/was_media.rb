
# download and extract was_nd install media from s3.
directory node['websphere-test']['unzip_dir'] do
  recursive true
end

# WASND Media
split_array = node['websphere-test']['s3_zip'].split('/') # need to split the s3 path bucket/path_to_file to use in resource.

aws_s3_file node['websphere-test']['zip_file'] do
  bucket split_array.first
  remote_path split_array[1..-1].join('/')
  checksum node['websphere-test']['zip_sha265']
  aws_access_key node['websphere-test']['aws']['access_key_id']
  aws_secret_access_key node['websphere-test']['aws']['access_key_secret']
  region node['websphere-test']['aws']['region']
  action :create_if_missing
end

execute 'unzip WASND media' do
  command "unzip -o #{node['websphere-test']['zip_file']} -d #{node['websphere-test']['unzip_dir']}"
  not_if { ::File.exist?("#{node['websphere-test']['repo_dir']}/repository.config") }
end

# WASND_SUPPL Media
split_array = node['websphere-test']['suppl_s3_zip'].split('/') # need to split the s3 path bucket/path_to_file to use in resource.
Chef::Log.warn("blah  file: #{node['websphere-test']['zip_file']} bucket: #{split_array.first} "\
  "path: #{split_array[1..-1].join('/')} id: #{node['websphere-test']['aws']['access_key_id']} "\
  "key: #{node['websphere-test']['aws']['access_key_secret']}")

aws_s3_file node['websphere-test']['suppl_zip_file'] do
  bucket split_array.first
  remote_path split_array[1..-1].join('/')
  checksum node['websphere-test']['suppl_zip_sha265']
  aws_access_key node['websphere-test']['aws']['access_key_id']
  aws_secret_access_key node['websphere-test']['aws']['access_key_secret']
  region node['websphere-test']['aws']['region']
end

execute 'unzip WASND_SUPPL media' do
  command "unzip -o #{node['websphere-test']['suppl_zip_file']} -d #{node['websphere-test']['suppl_unzip_dir']}"
  not_if { ::File.exist?("#{node['websphere-test']['suppl_repo']}/repository.config") }
end
