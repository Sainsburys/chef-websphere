#
# Cookbook:: websphere
# Resource:: websphere_app_server
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_cluster'

module WebsphereCookbook
  class WebsphereAppServer < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_app_server
    provides :websphere_app_server
    property :server_name, String, name_property: true
    property :node_name, [String, nil], required: true
    property :generate_unique_ports, [true, false], default: true
    property :attributes, [Hash, nil]

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
