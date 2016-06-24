
node.default['build-essential']['compile_time'] = true
include_recipe 'build-essential'

pkgs = %w(
  glibc.i686
  glibc
  libgcc.i686
  compat-libstdc++-33
  compat-db
)

package pkgs
