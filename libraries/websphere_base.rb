#
# Cookbook Name:: websphere
# Resource:: websphere-server
#
# Copyright (C) 2015 J Sainsburys
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# rubocop:disable Metrics/ClassLength
module WebsphereCookbook
  class WebsphereBase < Chef::Resource
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_base
    property :websphere_root, String, default: '/opt/IBM/WebSphere/AppServer'
    property :bin_dir, String, default: lazy { "#{websphere_root}/bin" }
    property :admin_user, [String, nil], default: nil
    property :admin_password, [String, nil], default: nil
    property :dmgr_host, String, default: 'localhost' # dmgr host to federate to.
    property :dmgr_port, [String, nil], default: nil # dmgr port to federate to.

    # you need at least one action here to allow the action_class.class_eval block to work
    action :dummy do
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def manageprofiles_exec(cmd, options)
        command = "#{cmd} #{options}"

        execute "manage_profiles #{cmd} #{profile_name}" do
          cwd bin_dir
          command command
          sensitive false
          action :run
        end
      end

      # returns a hash of enpoint => port for a server
      # if server is nil it returns an array of all servers endpoints and ports
      # returns nil if error
      def get_ports(srvr_name='', bin_directory='/opt/IBM/WebSphere/AppServer/bin')
        cookbook_file "#{bin_directory}/server_ports.py" do
          cookbook 'ibm-websphere'
          source 'server_ports.py'
          mode '0755'
          action :create
        end

        cmd = "-f server_ports.py #{srvr_name}"
        mycmd = wsadmin_returns(cmd)
        return nil if mycmd.error?
        str = mycmd.stdout.match(/===(.*?)===/m)
        return nil if str.nil?
        json_str = str[1].strip.gsub("'", '"') # strip and replace ' with " so it's a valid json str
        endpoints = JSON.parse(json_str)
        endpoints
      end

      def stop_profile_node(p_name, profile_bin)
        cmd = "./stopNode.sh -profileName #{p_name} -stopservers"
        cmd << " -username #{admin_user} -password #{admin_password}" if admin_user && admin_password

        execute "stop #{p_name}" do
          cwd profile_bin
          command cmd
          returns [0, 246, 255]
          # sensitive true   # TODO: uncomment this
          action :run
        end
      end

      # starts a node.
      # requires path to profiles own bin dir
      # TODO: add check if node or server are already started first.
      def start_node(profile_bin)
        # start_profile(profile_name, "#{profile_path}/bin", "./startNode.sh", [0, 255])
        execute "start node on profile: #{profile_bin}" do
          cwd profile_bin
          command './startNode.sh'
          returns [0, 255] # ignore error if node already started.
          action :run
        end
      end

      # starts a dmgr node.
      # requires path to profiles own bin dir
      # TODO: add check if node or server are already started first.
      def start_manager(p_name)
        # start_profile(profile_name, bin_dir, "./startManager.sh -profileName #{profile_name}", [0, 255])
        execute "start dmgr profile: #{p_name}" do
          cwd bin_dir
          command "./startManager.sh -profileName #{p_name}"
          returns [0, 255] # ignore error if node already started.
          action :run
        end
      end

      # use to setup a nodeagent or dmgr as an init.d service
      # server_name should be 'dmgr' or 'nodeagent'
      def enable_as_service(service_name, srvr_name, prof_path, runas='root')
        # if dplymgr user and password set, then add as additional args for stop.
        stop_args = admin_user && admin_password ? "-username #{admin_user} -password #{admin_password}" : ''
        # admin_user && admin_password ? start_args = "-username #{admin_user} -password #{admin_password}" : start_args = ''

        template "/etc/init.d/#{service_name}" do
          mode '0755'
          source 'node_service_init.d.erb'
          cookbook 'ibm-websphere'
          variables(
            service_name: service_name,
            server_name: srvr_name,
            profile_path: prof_path,
            was_root: bin_dir,
            stop_args: stop_args,
            start_args: '',
            runas_user: runas
          )
        end

        service service_name do
          action :enable
        end
      end

      # federates a node to a dmgr.
      # requires path to profiles own bin dir
      def add_node(profile_bin_dir)
        cmd = "./addNode.sh #{dmgr_host}"
        cmd << " #{dmgr_port}" if dmgr_port
        cmd << ' -includeapps'
        cmd << " -username #{admin_user} -password #{admin_password}" if admin_user && admin_password

        execute "addNode #{profile_bin_dir}" do
          cwd profile_bin_dir
          command cmd
          # sensitive true TODO: uncomment this and add unit test
          action :run
        end
        save_config
      end

      # see here for the caveats and operations performed by remove_node:
      # https://www-01.ibm.com/support/knowledgecenter/SSAW57_8.5.5/com.ibm.websphere.nd.iseries.doc/ae/rxml_removenode.html?lang=en
      # you cannot remove a custom/cell node, you need to just delete it and run cleanup_node instead.
      # only use remove_node if you intend to keep the appservers rather than delete them.
      def remove_node
        cmd = './removeNode.sh'
        cmd << " -username #{admin_user} -password #{admin_password}" if admin_user && admin_password

        execute "removeNode #{profile_bin_dir}" do
          cwd bin_dir
          command cmd
          sensitive true
          action :run
        end
      end

      # run after deleting a federated profile/node
      def cleanup_node(nde_name)
        cmd = "./cleanupNode.sh #{nde_name} #{dmgr_host}"
        cmd << " #{dmgr_port}" if dmgr_port
        # cmd << " -profileName #{dmgr_name}" # hoping we don't need the dmgr's profileName for simplicity
        cmd << " -username #{admin_user} -password #{admin_password}" if admin_user && admin_password
        execute "cleanupNode node: #{nde_name} dmgr: #{dmgr_host}" do
          cwd bin_dir
          command cmd
          sensitive true
          action :run
        end
      end

      def update_registry
        execute 'update profile registry' do
          cwd bin_dir
          command './manageprofiles.sh -validateAndUpdateRegistry'
          action :run
        end
      end

      def profile_exists?(p_name)
        mycmd = Mixlib::ShellOut.new('./manageprofiles.sh -listProfiles', cwd: bin_dir)
        mycmd.run_command
        return false if mycmd.error?
        # ./manageprofiles.sh -listProfiles example output: [Dmgr01, AppSrv01, AppSrv02]
        profiles_array = mycmd.stdout.chomp.gsub(/\[|\]/, '').split(', ') # trim '[' and ']' chars from string and convert to array
        return false if profiles_array.nil?
        profiles_array.each do |p|
          if p_name == p
            Chef::Log.debug("Profile #{p_name} exists")
            return true
          end
        end
        Chef::Log.debug("Profile #{p_name} does NOT exist")
        false
      end

      def delete_profile(p_name, p_path)
        execute "delete #{p_name}" do
          cwd bin_dir
          command "./manageprofiles.sh -delete -profileName #{p_name} && "\
            './manageprofiles.sh -validateAndUpdateRegistry'
          returns [0, 2] # TODO: find out why there are always minor errors when deleting a profile.
          action :run
        end

        directory p_path do
          recursive true
          action :delete
        end
      end

      # enables javasdk.
      # Use the profiles own bin dir
      # java sdk must already be installed with ibm-installmgr cookbook
      def enable_java_sdk(sdk_name, profile_bin, profile_name)
        cmd = "./managesdk.sh -enableProfile -profileName #{profile_name} -sdkname #{sdk_name} -verbose -enableServers"
        cmd << " -user #{admin_user} -password #{admin_password}" if admin_user && admin_password
        execute "enable java #{sdk_name} on profile: #{profile_name}" do
          cwd profile_bin
          command cmd
          action :run
        end
        save_config
      end

      # executes wsadmin commands and captures stdout, return values, errors etc.
      # returns  Mixlib::ShellOut with the stdout, stderror and exitcodes populated.
      # command needs to include the -f of -c flag for file or command string
      def wsadmin_returns(cmd, bin_directory = bin_dir)
        wsadmin_cmd = './wsadmin.sh -lang jython -conntype SOAP '
        wsadmin_cmd << "-host #{dmgr_host} " if dmgr_host
        wsadmin_cmd << "-port #{dmgr_port} " if dmgr_port
        wsadmin_cmd << "-user #{admin_user} -password #{admin_password} " if admin_user && admin_password
        wsadmin_cmd << cmd
        mycmd = Mixlib::ShellOut.new(wsadmin_cmd, cwd: bin_directory)
        mycmd.run_command

        Chef::Log.debug("wsadmin_returns cmd: #{cmd} stdout: #{mycmd.stdout} stderr: #{mycmd.stderr}")
        mycmd
      end

      # returns an array of key,value arrays containing server info.
      # eg. ["[cell", "MyNewCell]", "[serverType", "APPLICATION_SERVER]", "[com.ibm.websphere.baseProductVersion", "8.5.5.0]",
      # "[node", "AppServer10_node]", "[server", "AppServer10_server]"]
      # returns an empty array if server doesn't exit.
      def server_info(serv_name)
        cmd = " -c \"AdminServerManagement.showServerInfo('#{node_name}', '#{serv_name}')\""
        mycmd = wsadmin_returns(cmd)
        return [] if mycmd.error?
        str = result.stdout.match(/\['(.*?)'\]/).captures.first # match everything between ['']
        info_array = str.chomp.split("', '")
        info_array
      end

      def cluster_exists?(clus_name)
        cmd = "-c \"AdminClusterManagement.checkIfClusterExists('#{clus_name}')\""
        mycmd = wsadmin_returns(cmd)
        return true if mycmd.stdout.include?("\n \n'true'\n")
        false
      end

      # returns true if server name is a member of specified cluster.
      def member?(clus_name, serv_name)
        cmd = "-c \"AdminClusterManagement.checkIfClusterMemberExists('#{clus_name}', '#{serv_name}')\""
        mycmd = wsadmin_returns(cmd)
        if mycmd.stdout.include?("\n'true'\n")
          Chef::Log.debug("Server: #{serv_name} IS a member of cluster: #{clus_name}")
          return true
        end
        Chef::Log.debug("Server: #{serv_name} is NOT a member of cluster: #{clus_name}")
        false
      end

      # if server is a cluster member, it returns the cluster name
      # returns nil is server is not part of a cluster
      def member_of_cluster?(serv_name)
        clusters.each do |cluster|
          return cluster if member?(cluster, serv_name)
        end
        nil
      end

      def node_has_clustered_servers?(node_name)
        svrs = get_servers('APPLICATION_SERVER', node_name)
        svrs.each do |s|
          my_cluster = member_of_cluster?(s['server'])
          return true unless my_cluster.nil?
        end
        false
      end

      # returns an array of cluster names
      def clusters
        cmd = '-c "AdminClusterManagement.listClusters()"'
        mycmd = wsadmin_returns(cmd)
        cluster_array = []
        return cluster_array if mycmd.error?
        # example output last line: ['test1(cells/MyNewCell/clusters/test1|cluster.xml#ServerCluster_1454497648498)',
        # 'test2(cells/MyNewCell/clusters/test2|cluster.xml#ServerCluster_1454497723266)']
        str = mycmd.stdout.chomp.match(/\['(.*?)'\]/) # get only what's between [''].
        return cluster_array if str.nil?
        str_match = str.captures.first # get the first match only, removing outer brackets ['']
        raw_clusters = str_match.split("', '")
        raw_clusters.each do |c|
          cluster = c.split('(')[0]
          cluster_array << cluster
        end
        Chef::Log.debug("getclusters() result #{cluster_array}")
        cluster_array
      end

      def get_cluster_members(clus_name)
        cmd = "-c \"AdminClusterManagement.listClusterMembers('#{clus_name}')\""
        mycmd = wsadmin_returns(cmd)
        # example output: ['AdditionalAppServer_server(cells/MyNewCell/clusters/MyCluster03|cluster.xml#ClusterMember_1455629129667)']
        members = []
        return members if mycmd.error?
        str = mycmd.stdout.chomp.match(/\['(.*?)'\]/) # get only what's between [''].
        return members if str.nil?
        str_match = str.captures.first
        # get the first match only, removing outer brackets ['']
        raw_servers = str_match.split("', '")
        raw_servers.each do |s|
          server = s.split('(')[0]
          members << server
        end
        Chef::Log.debug("get_cluster_members() result #{members}")
      end

      # returns true if server exists on node.
      def server_exists?(nde_name, serv_name, profile_bin_dir = bin_dir)
        cmd = "-c \"AdminServerManagement.checkIfServerExists('#{nde_name}', '#{serv_name}')\""
        mycmd = wsadmin_returns(cmd, profile_bin_dir)
        return true if mycmd.stdout.include?("\n'true'\n")
        false
      end

      # returns an array of hashes {"server" => "myserver", "node" => "myserversnode"}.
      # server_type or node_name or both can be nil.
      # eg. if both are nil it will return all servers of all types on all nodes.
      def get_servers(server_type, node_name)
        cmd = "-c \"AdminServerManagement.listServers('#{server_type}', '#{node_name}')\""
        mycmd = wsadmin_returns(cmd)
        return [] if mycmd.error?
        str = mycmd.stdout.match(/\['(.*?)'\]/)
        return [] if str.nil?
        str_match = str.captures.first # match everything between ['']
        raw_array = str_match.chomp.split("', '") # example output ["AppSrv09_server(cells/MyNewCell/nodes/AppSrv09_node/servers/AppSrv09_server|server.xml#Server_1183122130078)"]

        hash_array = []
        raw_array.each do |raw_server|
          server = raw_server.split('(')[0]
          node = raw_server.match(%r{(?<=nodes\/).*?(?=\/servers)}).to_s
          hash_array << { 'server' => server, 'node' => node }
        end
        Chef::Log.debug("get_servers() result #{hash_array}")
        hash_array
      end

      # TODO: find a better way to retrieve a profiles current federated state.
      # If a nodeagent/server.xml file exists then it is assumed the node is already federated
      def federated?(p_path, node_name1)
        current_cell = profile_cell(p_path)
        if ::File.exist?("#{p_path}/config/cells/#{current_cell}/nodes/#{node_name1}/servers/nodeagent/server.xml")
          Chef::Log.debug("#{node_name1} is federated")
          return true
        else
          Chef::Log.debug("#{node_name1} is NOT federated")
          return false
        end
      end

      # executes wsadmin commands. Doesn't capture any stdout.
      def wsadmin_exec(label, cmd, return_codes = [0], bin_directory = bin_dir)
        wsadmin_cmd = './wsadmin.sh -lang jython -conntype SOAP '
        wsadmin_cmd << "-host #{dmgr_host} " if dmgr_host
        wsadmin_cmd << "-port #{dmgr_port} " if dmgr_port
        wsadmin_cmd << "-user #{admin_user} -password #{admin_password} " if admin_user && admin_password
        wsadmin_cmd << "-c \"#{cmd}\""
        Chef::Log.debug("wsadmin_exec running cmd: #{wsadmin_cmd}")

        execute "wsadmin #{label}" do
          cwd bin_directory
          command wsadmin_cmd
          returns return_codes
          # sensitive true TODO: MUST uncomment this before merging and have an accompaniying unit test
          action :run
        end
      end

      def save_config
        cmd = "AdminConfig.save()"
        wsadmin_exec("wsadmin save config", cmd)
      end

      def start_server(nde_name, serv_name)
        cmd = "AdminServerManagement.startSingleServer('#{nde_name}', '#{serv_name}')"
        wsadmin_exec("wsadmin start server: #{serv_name} on node #{nde_name}", cmd, [0, 103])
      end

      def stop_server(nde_name, serv_name)
        cmd = "AdminServerManagement.stopSingleServer('#{nde_name}', '#{serv_name}')"
        wsadmin_exec("wsadmin stop server: #{serv_name} on node #{nde_name}", cmd)
      end

      def stop_all_servers(nde_name)
        cmd = "AdminServerManagement.stopAllServers('#{nde_name}')"
        wsadmin_exec("wsadmin stoping all servers on node #{nde_name}", cmd, [0, 103])
      end

      def delete_server(nde_name, serv_name)
        cmd = "AdminServerManagement.deleteServer('#{nde_name}', '#{serv_name}')"
        wsadmin_exec("wsadmin delete server: #{serv_name} on node #{nde_name}", cmd)
      end

      def stop_node(nde_name)
        cmd = "AdminNodeManagement.stopNode('#{nde_name}')"
        wsadmin_exec("wsadmin stop node: #{nde_name}", cmd, [0, 103, 1])
      end

      def stop_node_agent(nde_name)
        cmd = "AdminNodeManagement.stopNode('#{nde_name}')"
        wsadmin_exec("wsadmin stop node agent: #{nde_name}", cmd, [0, 103, 1])
      end

      # deletes a cluster member server
      # there's no need to cleanup the server's orhpaned directory as it is removed lazily when
      # another server with the same name is created again.
      def delete_cluster_member(clus_name, member_name, member_node, delete_replicator)
        cmd = "AdminTask.deleteClusterMember('[-clusterName #{clus_name} -memberNode #{member_node} "\
          "-memberName #{member_name} -replicatorEntry [-deleteEntry #{delete_replicator}]]')"
        wsadmin_exec("wsadmin delete member: #{member_name} from cluster: #{clus_name}", cmd)
      end

      def delete_cluster(clus_name, repl_domain = false)
        cmd = "AdminTask.deleteCluster('[-clusterName #{clus_name} -replicationDomain [-deleteRepDomain #{repl_domain}]]')"
        wsadmin_exec("wsadmin delete cluster: #{clus_name}", cmd)
      end

      # returns the object id from a specified match string. matchen eg /Cell:MyNewCell/
      # eg result: 'MyNewCell(cells/MyNewCell|cell.xml#Cell_1)'
      # returns nil if error or no result.
      def get_id(matcher, bin_directory = bin_dir)
        cmd = "-c \"AdminConfig.getid('#{matcher}')\""
        mycmd = wsadmin_returns(cmd, bin_directory)
        return nil if mycmd.error?
        str = mycmd.stdout.match(/\n'(.*?)'\n/) # match everything between \n'capture this'\n
        return nil if str.nil? || str.captures.first == ''
        str.captures.first
      end

      # returns the top level attributes object id for a given object id.
      # eg object_id 'MyNewCell(cells/MyNewCell|cell.xml#Cell_1)'
      # eg returns '(cells/MyNewCell|cell.xml#MonitoredDirectoryDeployment_1)'
      def get_attribute_id(object_id, attr_name, bin_directory = bin_dir)
        cmd = "-c \"AdminConfig.showAttribute('#{object_id}', '#{attr_name}')\""
        mycmd = wsadmin_returns(cmd, bin_directory)
        return nil if mycmd.error?
        str = mycmd.stdout.match(/\n'(.*?)'\n/) # match everything between \n'capture this'\n
        return nil if str.nil?
        str.captures.first
      end

      # modifies the specified attribues associated with a given config_id
      # attr_key_val_list is a string with key, value pairs eg: "[['userID', 'newID'], ['password', 'newPW']]"
      def modify_object(config_id, attr_key_val_list, _bin_directory = bin_dir)
        cmd = "AdminConfig.modify('#{config_id}', #{attr_key_val_list})"
        Chef::Log.debug("Modifying #{config_id}' to #{attr_key_val_list}")
        wsadmin_exec("wsadmin modify config_id: #{config_id}", cmd)
        save_config
      end

      # updates attributes of an object.
      # attributes needs to be a nested hash of attributes and the names o their parents
      # eg. "processDefinitions" => {
      #     "monitoringPolicy" => {
      #       "newvalue" => "[['nodeRestartState', 'RUNNING']]" }}
      # parent should be the parent object id to the hash.
      # eg. AppServer12_server(cells/MyNewCell/nodes/AppServer12_node/servers/AppServer12_server|server.xml#Server_1183122130078)
      def update_attributes(attributes, parent)
        attributes.each do |key, val|
          if val.is_a?(Hash)
            parent_attr_id = get_attribute_id(parent, key)
            # convert to an array and iterate over it if needed.
            if str_array?(parent_attr_id)
              parent_attrs = str_to_array(parent_attr_id)
              parent_attrs.each do |p|
                update_attributes(val, p)
              end
            else
              update_attributes(val, parent_attr_id)
            end
          else
            Chef::Log.debug("Setting attributes on #{parent}")
            modify_object(parent, val)
          end
        end
      end

      # deploys an application to a cluster. app_file can be an .ear, .war or .jar
      # app_file is the full path to the application file.
      # if you need to map the app to a virtual host use map_web_mod_to_vh
      # eg. map_web_mod_to_vh=[['.*', '.*', 'default_host']]
      def deploy_to_cluster(appl_name, appl_file, clus_name, map_web_mod_to_vh = nil)
        cmd = "AdminApp.install('#{appl_file}', ['-appname', '#{appl_name}', '-cluster', '#{clus_name}'"
        cmd << ", '-MapWebModToVH', [['.*', '.*', 'default_host']]" if map_web_mod_to_vh
        cmd << '])'
        wsadmin_exec("wsadmin deploy #{appl_file} to cluster #{clus_name}", cmd)
        save_config
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
