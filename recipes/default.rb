pkgs = %w(
  glibc.i686
  glibc.x86_64
  libgcc.x86_64
  libgcc.i686
  compat-libstdc++-33
  compat-db
)

package pkgs do
  action :upgrade
end
