# see https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html
remote_file "#{Chef::Config['file_cache_path']}/awscliv2-latest.zip" do
  source "https://awscli.amazonaws.com/awscli-exe-linux-#{node['kernel']['machine']}-latest.zip"
  mode '755'
  action :create_if_missing
  notifies :run, 'execute[extract_awscli_installer]', :immediately
end

execute 'extract_awscli_installer' do
  cwd Chef::Config['file_cache_path']
  user 'root'
  group 'root'
  command 'unzip -o awscliv2-latest.zip'
  action :nothing
  notifies :run, 'execute[awscli_install]', :immediately
end

execute 'awscli_install' do
  cwd Chef::Config['file_cache_path']
  user 'root'
  group 'root'
  command "./aws/install --bin-dir #{node['gol']['awscli']['bin_dir']} --update"
  action :nothing
  notifies :run, 'execute[cleanup_awscli_installer]', :immediately
end

execute 'cleanup_awscli_installer' do
  cwd Chef::Config['file_cache_path']
  user 'root'
  group 'root'
  command 'rm -rf ./aws'
  action :nothing
end
