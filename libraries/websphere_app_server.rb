
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

      unless server_exists?(server_name, node_name)
          cmd = "AdminTask.createApplicationServer('#{node_name}', '[-name #{server_name} -genUniquePorts #{generate_unique_ports}]')"
          wsadmin_exec("wsadmin create app server: #{server_name} to node: #{node_name} ", cmd)
      end

      # set attributes on server
      ruby_block "set server #{server_name} attributes" do
        block do
          server_id = get_id("/Server:#{server_name}/")
          update_attributes(attributes, server_id) if !server_id.nil? && attributes
        end
        action :run
      end
      node.default['ibm-websphere']['endpoints'] = get_ports() #TODO: change this to not use node attributes somehow
      #Chef::Log.debug("endpoints set #{node['ibm-websphere']['endpoints'][server_node][server_name]}")
    end

    action :start do
      i = 0 # safety timeout break
      until server_exists?(node_name, server_name)
        sleep(5) # ensure webserver has been created first
        i += 1
        break if i >= 8
      end
      start_server(node_name, server_name, return_codes=[0, 103])

      node.default['ibm-websphere']['endpoints'] = get_ports()
      #Chef::Log.debug("endpoints set #{node['ibm-websphere']['endpoints'][server_node][server_name]}")
    end

    action :delete do
      delete_server(node_name, server_name)
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
    end
  end
end
