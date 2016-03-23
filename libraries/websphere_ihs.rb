module WebsphereCookbook
  class WebsphereIhs < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_ihs
    property :webserver_name, String, name_property: true
    property :plg_root, String, default: '/opt/IBM/Websphere/Plugins'
    property :wct_root, String, default: '/opt/IBM/Websphere/Toolbox'
    property :wct_tool_root, String, default: lazy { "#{wct_root}/WCT" }
    property :config_type, String, default: 'local_distributed', regex: /^(local_distributed|remote)$/ # currently only tested for local_distributed
    property :profile_name, String, required: true
    property :node_name, String, required: true
    property :profile_path, String, default: lazy { "#{websphere_root}/profiles/#{profile_name}" }
    property :map_to_apps, [TrueClass, FalseClass], default: false
    property :ihs_hostname, [String],  default: lazy { node.name }
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

    # 1. install required packages for wctcmd tool on centos 6
    # 2. install web definition by running wctcmd pct tool
    # 3. execute equivalient to contents of configure script file
    # 4. ensure module is added to apache and restart

    action :create do
      if platform_family?('rhel')
        pkgs = %w(glibc glibc.i686 libgcc libgcc.i686)
        pkgs.each do |pkg|
          package pkg
        end
      end

      create_web_definition unless web_definition_exists?
      run_configure_script unless server_exists?(node_name, webserver_name)

      template '/etc/init.d/ibm-httpd' do
        mode '0755'
        source 'ihs_init.d.erb'
        cookbook 'ibm-websphere'
        variables(
          ihs_root: ihs_install_root
        )
      end

      service 'ibm-httpd' do
        action :enable
      end
    end

    action :delete do
      delete_web_definition if web_definition_exists?
      # TODO: delete server as well?
    end

    action :start do
      execute "start webserver #{webserver_name}" do
        cwd ihs_install_root
        command "#{ihs_install_root}/bin/apachectl start"
        action :run
      end
    end

    action :stop do
      execute "start webserver #{webserver_name}" do
        cwd ihs_install_root
        command "#{ihs_install_root}/bin/apachectl stop"
        action :run
      end
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
          Chef::Log.warn('Error checking if web definition exists.')
          return false
        end
        if mycmd.stdout.include?('Path:')
          Chef::Log.warn('A Web definition already exists on this server.')
          return true
        end
        Chef::Log.warn('Web definition does NOT exist.')
        false
      end

      def run_configure_script
        # run configure script on dmgr
        # TODO: ensure this works when webserver is not on same server as dmgr

        configure_cmd = "#{profile_path}/bin/wsadmin.sh -profileName #{profile_name} "\
          "-user #{admin_user} -password #{admin_password} -f '#{bin_dir}/configureWebserverDefinition.jacl' "\
          "#{webserver_name} IHS '#{ihs_install_root}' '#{ihs_config_file}' #{ihs_port} MAP_ALL '#{plg_root}' "\
          "managed #{node_name} #{ihs_hostname} linux"

        execute "run webserver #{webserver_name} configure script" do
          cwd "#{profile_path}/bin"
          command configure_cmd
          # sensitive true TODO: MUST uncomment this before merging and have an accompaniying unit test
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
          # sensitive true TODO: MUST uncomment this before merging and have an accompaniying unit test
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
