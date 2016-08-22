
# This recipe removes dashes from the default aws hostname on a rhel based machine.
# IBM DB2 does not support dashes in the hostname
# eg a hostname of ip-10-8-192-13 will become ip10819213

fqdn = node['hostname'].delete!('-')
if fqdn
  fqdn = fqdn.sub('*', node.name)
  fqdn =~ /^([^.]+)/
  hostname = Regexp.last_match[1]

  node.override['new_hostname'] = hostname # because ohai reload doesn't work.
  ENV['HOSTNAME'] = hostname # A1 installer needs this

  aliases = [hostname]

  service 'network' do
    action :nothing
  end

  ohai 'reload_hostname' do
    plugin 'hostname'
    action :nothing
  end

  hostfile = '/etc/sysconfig/network'
  file hostfile do
    action :create
    content lazy {
      ::IO.read(hostfile).gsub(/^HOSTNAME=.*$/, "HOSTNAME=#{fqdn}")
    }
    notifies :reload, 'ohai[reload_hostname]', :immediately
    notifies :restart, 'service[network]', :immediately
  end

  # this is to persist the correct hostname after machine reboot
  sysctl = '/etc/sysctl.conf'
  file sysctl do
    action :create
    content lazy {
      ::IO.read(sysctl) + "kernel.hostname=#{hostname}\n"
    }
    not_if { ::IO.read(sysctl) =~ /^kernel\.hostname=#{hostname}$/ }
    notifies :reload, 'ohai[reload_hostname]', :immediately
    notifies :restart, 'service[network]', :immediately
  end

  execute "hostname #{hostname}" do
    only_if { node['hostname'] != hostname }
    notifies :reload, 'ohai[reload_hostname]', :immediately
  end

  hostsfile_entry 'set hostname' do
    ip_address '127.0.0.1'
    hostname fqdn
    aliases aliases
    unique true
    action :create
    notifies :reload, 'ohai[reload_hostname]', :immediately
  end

  hostsfile_entry 'localhost' do
    ip_address '127.0.0.1'
    hostname 'localhost'
    action :append
  end

  ohai 'reload' do
    action :reload
  end

  log "hostname #{hostname} node['hostname'] #{node['hostname']} " do
    level :warn
  end

else
  log 'Please set the set_fqdn attribute to desired hostname' do
    level :warn
  end
end
