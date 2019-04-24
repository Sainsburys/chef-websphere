
node.default['build-essential']['compile_time'] = true
# include_recipe 'build-essential'

if node['platform_version'].to_i >= 7 && platform_family?('rhel')
  include_recipe 'runit::default'
end

pkgs = %w[
  glibc.i686
  glibc.x86_64
  libgcc.x86_64
  libgcc.i686
  compat-libstdc++-33
  compat-db
]

package pkgs do
  action :upgrade
end
