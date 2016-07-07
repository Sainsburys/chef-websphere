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

require_relative 'websphere_dmgr'

module WebsphereCookbook
  class WebsphereProfile < WebsphereDmgr
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_profile
    property :profile_type, String, default: 'appserver', regex: /^(appserver|custom)$/
    property :attributes, [Hash, nil], default: nil # these are only set if the node is federated.

    # creates a new profile or augments/updates if profile exists.
    action :create do
      unless profile_exists?(profile_name)
        template_path = template_lookup(profile_type, profile_templates_dir)
        options = " -profileName '#{profile_name}' -profilePath '#{profile_path}' -templatePath '#{template_path}' -nodeName '#{node_name}'"
        options << " -serverName '#{server_name}'" if profile_type == 'appserver'
        options << " -cellName '#{cell_name}'" if cell_name
        # manageprofiles_exec('./manageprofiles.sh -create', options)

        cmd = "./manageprofiles.sh -create #{options}"

        execute "manage_profiles -create #{profile_name}" do
          cwd bin_dir
          command cmd
          sensitive true
          action :run
        end

        # set java sdk if set
        current_java = current_java_sdk(profile_name)
        enable_java_sdk(java_sdk, "#{profile_path}/bin", profile_name) if java_sdk && current_java != java_sdk # only update if java version changes
      end
    end

    action :federate do
      federated = federated?(profile_path, node_name)
      if profile_exists?(profile_name) && !federated
        add_node("#{profile_path}/bin")

        enable_as_service(node_name, 'nodeagent', profile_path)
        # action_start
      end

      # server_id = get_id("/Server:#{server_name}/", "#{profile_path}/bin]")
      # update_attributes(attributes, server_id) if !server_id.nil? && attributes

      # set attributes on server
      ruby_block 'set server attributes' do
        block do
          server_id = get_id("/Server:#{server_name}/")
          update_attributes(attributes, server_id) if federated?(profile_path, node_name) && !server_id.nil? && attributes
        end
        action :run
        # subscribes :run, "execute[addNode #{profile_path}/bin]", :delayed
      end
    end

    action :start do
      start_node("#{profile_path}/bin") if federated?(profile_path, node_name)
      start_server(node_name, server_name) if profile_type == 'appserver'
    end

    action :stop do
      stop_all_servers(node_name)
      stop_node(node_name)
      stop_node_agent(node_name) if federated?(profile_path, node_name)
      stop_profile_node(profile_name, "#{profile_path}/bin")
    end

    action :delete do
      update_registry
      if profile_exists?(profile_name)
        Chef::Log.fatal("Refusing to delete profile #{profile_name} node: #{node_name} as it contains clustered servers. "\
          'Please remove clustered servers first.') if node_has_clustered_servers?(node_name)
        federated = federated?(profile_path, node_name)
        # stop_all_servers(node_name)
        # stop_node(node_name)
        # stop_node_agent(node_name) if federated
        # stop_profile_node(profile_name, "#{profile_path}/bin")
        action_stop

        # remove_node(bin_dir) if federated?(profile_path, node_name) # this is only valid for federated appservers profiles
        delete_profile(profile_name, profile_path)
        cleanup_node(node_name) if federated
      end
    end

    action :sync_and_restart do
      # syncs node config to dmgr. shutsdown servers if needed and restart node agent.
      sync_node_sh("#{profile_path}/bin", true, true)
    end

    action :sync do
      # syncs nodes without restarting nodeagent or servers
      sync_node_wsadmin(node_name, "#{profile_path}/bin")
    end

    action :start_all_servers do
      start_all_servers(profile_name)
    end

  end
end
