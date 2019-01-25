#
# Cookbook Name:: websphere
# Resource:: websphere_profile
#
# Copyright (C) 2015-2019 J Sainsburys
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
    property :profile_type, String, default: 'custom', regex: /^(appserver|custom)$/
    property :attributes, [Hash, nil], default: nil # these are only set if the node is federated.
    property :server_name, [String, nil], default: nil
    property :manage_user, [TrueClass, FalseClass], default: true
    property :manage_service, [TrueClass, FalseClass], default: true

    # creates a new profile or augments/updates if profile exists.
    action :create do
      unless profile_exists?(new_resource.profile_name)
        template_path = template_lookup(new_resource.profile_type, new_resource.profile_templates_dir)
        options = " -profileName '#{new_resource.profile_name}' -profilePath '#{new_resource.profile_path}' -templatePath '#{template_path}' -nodeName '#{new_resource.node_name}'"
        options << " -serverName '#{new_resource.server_name}'" if new_resource.profile_type == 'appserver' && !new_resource.server_name.nil?
        options << " -cellName '#{new_resource.cell_name}'" if new_resource.cell_name

        cmd = "./manageprofiles.sh -create #{options}"

        execute "manage_profiles -create #{new_resource.profile_name}" do
          cwd new_resource.bin_dir
          command cmd
          user new_resource.run_user
          group new_resource.run_group
          sensitive true
          action :run
        end

        # Enable "profile_name" to use the specific "java_sdk"
        if new_resource.java_sdk
          current_java = current_java_sdk(new_resource.profile_name)
          enable_java_sdk(new_resource.java_sdk, "#{new_resource.profile_path}/bin", new_resource.profile_name) if current_java != new_resource.java_sdk
        end
      end
    end

    action :federate do
      federated = federated?(new_resource.profile_path, new_resource.node_name)
      if profile_exists?(new_resource.profile_name) && !federated
        add_node("#{new_resource.profile_path}/bin")
        unless new_resource.run_user == 'root' || new_resource.manage_user == false
          create_service_account(new_resource.run_user, new_resource.run_group)
        end
        enable_as_service(new_resource.node_name, 'nodeagent', new_resource.profile_path, new_resource.run_user) if new_resource.manage_service == true
      end

      # set attributes on server
      ruby_block 'set server attributes' do
        block do
          server_id = get_id("/Server:#{new_resource.server_name}/")
          update_attributes(new_resource.attributes, server_id) if federated?(new_resource.profile_path, new_resource.node_name) && !server_id.nil? && new_resource.attributes
        end
        action :run
        not_if { new_resource.server_name.nil? }
        # subscribes :run, "execute[addNode #{profile_path}/bin]", :delayed
      end
    end

    action :start do
      start_node("#{new_resource.profile_path}/bin") if federated?(new_resource.profile_path, new_resource.node_name)
      start_server(new_resource.node_name, new_resource.server_name) if new_resource.profile_type == 'appserver' && !new_resource.server_name.nil?
    end

    action :stop do
      stop_all_servers(new_resource.node_name)
      stop_node(new_resource.node_name)
      stop_node_agent(new_resource.node_name) if federated?(new_resource.profile_path, new_resource.node_name)
      stop_profile_node(new_resource.profile_name, "#{new_resource.profile_path}/bin")
    end

    # rubocop:disable Style/MultilineIfModifier
    action :delete do
      update_registry
      if profile_exists?(new_resource.profile_name)
        Chef::Log.fatal(
          "Refusing to delete profile #{new_resource.profile_name} node: #{new_resource.node_name} as it contains clustered servers. "\
          'Please remove clustered servers first.') if node_has_clustered_servers?(new_resource.node_name)
        federated = federated?(new_resource.profile_path, new_resource.node_name)
        action_stop

        # remove_node(bin_dir) if federated?(profile_path, node_name) # this is only valid for federated appservers profiles
        delete_profile(new_resource.profile_name, new_resource.profile_path)
        cleanup_node(new_resource.node_name) if federated
      end
    end
    # rubocop:enable Style/MultilineIfModifier

    action :sync_and_restart do
      # syncs node config to dmgr. shutsdown servers if needed and restart node agent.
      sync_node_sh("#{new_resource.profile_path}/bin", true, true)
    end

    action :sync do
      # syncs nodes without restarting nodeagent or servers
      sync_node_wsadmin(new_resource.node_name, "#{new_resource.profile_path}/bin")
    end

    action :start_all_servers do
      start_all_servers(new_resource.profile_name)
    end
  end
end
