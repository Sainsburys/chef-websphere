#
# Cookbook Name:: websphere
# Resource:: websphere_app_server
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

require_relative 'websphere_cluster'

module WebsphereCookbook
  class WebsphereAppServer < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_app_server
    property :server_name, String, name_property: true
    property :node_name, [String, nil], default: nil, required: true
    property :generate_unique_ports, [TrueClass, FalseClass], default: true
    property :attributes, [Hash, nil], default: nil

    action :create do
      unless server_exists?(new_resource.node_name, new_resource.server_name)
        cmd = "AdminTask.createApplicationServer('#{new_resource.node_name}', '[-name #{new_resource.server_name} -genUniquePorts #{new_resource.generate_unique_ports}]')"
        wsadmin_exec("create app server: #{new_resource.server_name} to node: #{new_resource.node_name} ", cmd)
      end

      # set attributes on server
      ruby_block "set server #{new_resource.server_name} attributes" do
        block do
          server_id = get_id("/Node:#{new_resource.node_name}/Server:#{new_resource.server_name}/")
          update_attributes(new_resource.attributes, server_id) if !server_id.nil? && new_resource.attributes
        end
        action :run
      end
      node.default['websphere']['endpoints'] = get_ports # TODO: change this to not use node attributes somehow
      # Chef::Log.debug("endpoints set #{node['websphere']['endpoints'][server_node][server_name]}")
    end

    action :start do
      i = 0 # safety timeout break
      until server_exists?(new_resource.node_name, new_resource.server_name)
        sleep(5) # ensure webserver has been created first
        i += 1
        break if i >= 8
      end
      start_server(new_resource.node_name, new_resource.server_name, [0, 103])

      node.default['websphere']['endpoints'] = get_ports
      # Chef::Log.debug("endpoints set #{node['websphere']['endpoints'][server_node][server_name]}")
    end

    action :delete do
      delete_server(new_resource.node_name, new_resource.server_name)
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
    end
  end
end
