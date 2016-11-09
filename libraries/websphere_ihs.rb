module WebsphereCookbook
  class WebsphereIhs < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_ihs
    property :webserver_name, String, name_property: true
    property :plg_root, String, default: '/opt/IBM/WebSphere/Plugins'
    property :wct_root, String, default: '/opt/IBM/WebSphere/Toolbox'
    property :wct_tool_root, String, default: lazy { "#{wct_root}/WCT" }
    property :config_type, String, default: 'local_distributed', regex: /^(local_distributed|remote)$/ # currently only tested for local_distributed
    property :profile_name, String, required: false # only valid for local_distributed installations
    property :node_name, String, required: true
    property :profile_path, String, default: lazy { "#{websphere_root}/profiles/#{profile_name}" }
    property :map_to_apps, [TrueClass, FalseClass], default: false
    property :ihs_hostname, [String],  default: lazy { node.hostname }
    property :ihs_port, String, default: '80'
    property :ihs_install_root, default: '/opt/IBM/HTTPServer'
    property :ihs_config_file, String, default: lazy { "#{ihs_install_root}/conf/httpd.conf" }
    property :install_arch, String, default: '64'
    property :runas_user, String, default: 'root'
    property :runas_group, String, default: 'root'
    property :enable_ihs_admin_server, [TrueClass, FalseClass], default: false
    property :ihs_admin_user, [String, nil], default: nil
    property :ihs_admin_password, [String, nil], default: nil
    property :ihs_admin_port, String, default: '8008'

    # pre-requisite: this library only supports ih webservers on managed nodes. The websphere node must already be created on the ihs node.
    # 1. install required packages for wctcmd tool on centos 6
    # 2. install web definition by running wctcmd pct tool
    # 3. execute equivalient to contents of configure script file
    # 4. ensure module is added to apache and restart

    action :create do
      if platform_family?('rhel')
        pkgs = %w(glibc.i686 glibc libgcc.i686)
        pkgs.each do |pkg|
          package pkg
        end
      end

      create_web_definition unless web_definition_exists?
      run_configure_script unless server_exists?(node_name, webserver_name)

      template '/etc/init.d/ibm-httpd' do
        mode '0755'
        source 'ihs_init.d.erb'
        cookbook 'websphere'
        variables(
          ihs_root: ihs_install_root
        )
      end

      service 'ibm-httpd' do
        action :enable
      end

      save_config
      sync_node_wsadmin(node_name)
    end

    action :delete do
      delete_web_definition if web_definition_exists?
      save_config
      # TODO: delete server as well?
    end

    action :start do
      i = 0 # safety timeout break
      until server_exists?(node_name, webserver_name)
        sleep(5) # ensure webserver has been created first
        i += 1
        break if i >= 8
      end
      start_server(node_name, webserver_name, [0, 103])
    end

    action :stop do
      stop_server(node_name, webserver_name)
    end

    action :restart do
      i = 0 # safety timeout break
      until server_exists?(node_name, webserver_name)
        sleep(5) # ensure webserver has been created first
        i += 1
        break if i >= 8
      end
      stop_server(node_name, webserver_name)
      start_server(node_name, webserver_name, [0, 103])
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      # checks if a web definition has already been defined on this server.
      # you can only have one per definition location
      def web_definition_exists?
        # create webserver definition
        mycmd = Mixlib::ShellOut.new('./wctcmd.sh -tool pct -listDefinitionLocations', cwd: wct_tool_root)
        mycmd.run_command
        if mycmd.error?
          Chef::Log.warn("Error checking if web definition exists: #{mycmd.stderr}")
          return false
        end
        if mycmd.stdout.include?('Path:')
          Chef::Log.warn('A Web definition already exists on this server.')
          return true
        end
        Chef::Log.warn('Web definition does NOT exist.')
        false
      end

      # This method runs configureWebserverDefinition.jacl script passing in paramaters.
      # wsadmin.sh -user WASadminUsername -password WASadminPassword -f ${WAS_HOME}/bin/configureWebserverDefinition.jacl
      #  webserverName webserverType webserverInstallLocation webserverConfigFile webserverPort
      #   mapApplications pluginInstallLocation webserverNodeType webserverNodeName webserverHostName webserverOS adminPort adminUserID adminPassword
      # Details of each attribute:
      # WASadminUsername         : User Name for WAS Adminstration
      # WASadminPassword         : Password  for WAS Adminstration
      # webserverName            : Name of the webserver to be defined
      # webserverType            : Type of the web server. Valid values are: IHS APACHE IPLANET DOMINO IIS HTTPSERVER_ZOS
      # webserverInstallLocation : Location of the websserver install
      # webserverConfigFile      : Webserver configuration file
      # webserverPort            : Listening port of the web server
      # mapApplications          : Specifies whether the existing applications are to be mapped to the web server. Valid values are: MAP_NONE MAP_DEFAULT MAP_ALL
      # pluginInstallLocation    : Location of the plugin install
      # webserverNodeType        : Type of the node holding webserver definition, valid values are: managed unmanaged
      # webserverNodeName        : Node at which web server should be defined
      # webserverHostName        : Host name of the web server Needed only for unmanaged node
      # webserverOS              : Operating system of the web server machine Needed only for unmanaged node Valid values are: windows solaris aix hpux linux os400 os390
      # adminPort                : IHS Remote Administration port Needed only for IHS webserver Defaults to 2001 for os400 Defaults to 8008 for other platforms
      # adminUserID              : IHS Remote Administration userid Needed only for IHS webserver
      # adminPassword            : IHS Remote Administration password Needed only for IHS webserver
      # serviceName              : Service name for the webserver Needed only for IHS webserver
      def run_configure_script
        # run configure script on dmgr

        # /opt/IBM/WebSphere/AppServer/profiles/A1_profile/bin/wsadmin.sh -profileName A1_profile -user idadmin -password 99Pr0blems
        # -f '/opt/IBM/WebSphere/AppServer/bin/configureWebserverDefinition.jacl' Webserver01 IHS '/opt/IBM/HTTPServer'
        #     '/opt/IBM/HTTPServer/servers/Webserver01/conf/httpd-Webserver01.conf' 1143 MAP_ALL
        # '/opt/IBM/WebSphere/Plugins' managed ip-10-1-1-191_Node01 ibm-ihs-managed-centos-6 linux

        configure_cmd = "#{profile_path}/bin/wsadmin.sh -profileName #{profile_name} "\
          "-user #{admin_user} -password #{admin_password} -f '#{bin_dir}/configureWebserverDefinition.jacl' "\
          "#{webserver_name} IHS '#{ihs_install_root}' '#{ihs_config_file}' #{ihs_port} MAP_ALL '#{plg_root}' "\
          "managed #{node_name} #{ihs_hostname} linux"

        execute "run webserver #{webserver_name} configure script" do
          cwd "#{profile_path}/bin"
          command configure_cmd
          sensitive true
          action :run
        end
      end

      def create_web_definition
        # create webserver definition
        cmd = "./wctcmd.sh -tool pct -createDefinition -defLocPathname #{plg_root} -defLocName #{webserver_name} "\
          "-configType #{config_type} -enableAdminServerSupport #{enable_ihs_admin_server} -enableUserAndPass #{enable_ihs_admin_server} "\
          "-mapWebServerToApplications #{map_to_apps} -profileName #{profile_name} -wasExistingLocation #{websphere_root} "\
          "-webServerConfigFile1 #{ihs_config_file} -webServerDefinition #{webserver_name} -webServerPortNumber #{ihs_port} -webServerSelected ihs "\
          "-webServerHostName #{ihs_hostname} -ihsAdminUnixUserGroup #{runas_group} -ihsAdminUnixUserID #{runas_user}"
        cmd << " -ihsAdminUserID #{ihs_admin_user} -ihsAdminPassword #{ihs_admin_password}" if enable_ihs_admin_server && ihs_admin_user && ihs_admin_password

        execute "create webserver definition: #{webserver_name}" do
          cwd wct_tool_root
          command cmd
          sensitive true
          action :run
        end
      end

      def delete_web_definition
        cmd = "./wctcmd.sh -tool pct -removeDefinitionLocation -defLocPathname #{plg_root}"
        execute "delete webserver definition: #{webserver_name}" do
          cwd wct_tool_root
          command cmd
          action :run
        end
      end
    end
  end
end
