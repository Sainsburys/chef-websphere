
require_relative 'websphere_cluster'

module WebsphereCookbook
  class WebsphereClusterMember < WebsphereCluster
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_cluster_member
    property :server_name, String, name_property: true
    property :server_node, [String, nil], default: nil, required: true
    property :member_weight, Fixnum, default: 2 # number from 0-100. Higher weight gets more traffic
    property :session_replication, [TrueClass, FalseClass], default: false
    property :resources_scope, String, default: 'both', regex: /^(both|server|cluster)$/
    property :generate_unique_ports, [TrueClass, FalseClass], default: true
    property :attributes, [Hash, nil], default: nil

    # creates a new profile or augments/updates if profile exists.
    action :create do
      # make sure cluster exists, and we're not adding a server that already exists in a cluster.
      if cluster_exists?(cluster_name) && !member_of_cluster?(server_name)
        if get_cluster_members(cluster_name).count > 0
          # this will NOT be the first member. add as additional
          cmd = "AdminTask.createClusterMember(['-clusterName', '#{cluster_name}', '-memberConfig', '[-memberNode #{server_node} "\
            "-memberName #{server_name} -memberWeight #{member_weight} -genUniquePorts #{generate_unique_ports} -replicatorEntry #{session_replication}]'])"
          wsadmin_exec("wsadmin add additional member: #{server_name} to cluster: #{cluster_name} ", cmd)
        else
          # this will be the first member and be the template for further cluster members
          cmd = "AdminClusterManagement.createFirstClusterMemberWithTemplate('#{cluster_name}', '#{server_node}', '#{server_name}', 'default')"
          wsadmin_exec("wsadmin add first cluster member: #{server_name} to cluster: #{cluster_name} ", cmd)
        end
      end

      # set attributes on server
      ruby_block 'set clustered server attributes' do
        block do
          server_id = get_id("/Node:#{server_node}/Server:#{server_name}/")
          update_attributes(attributes, server_id) if !server_id.nil? && attributes
        end
        action :run
      end
      node.default['ibm-websphere']['endpoints'] = get_ports
      # Chef::Log.debug("endpoints set #{node['ibm-websphere']['endpoints'][server_node][server_name]}")
      save_config
    end

    action :start do
      # it can take a minute to create the clustered server, so we need to add a delay in if it cannot find it.
      sleep(30) if !server_exists?(server_node, server_name) || !member?(cluster_name, server_name)
      sleep(30) if !server_exists?(server_node, server_name) || !member?(cluster_name, server_name)
      start_server(server_node, server_name) if server_exists?(server_node, server_name) || member?(cluster_name, server_name)
      # node.normal['ibm-websphere']['endpoints'][server_name] = get_ports(server_node,server_name)
      node.default['ibm-websphere']['endpoints'] = get_ports
      # Chef::Log.debug("endpoints set #{node['ibm-websphere']['endpoints'][server_node][server_name]}")
    end

    action :delete do
      # TODO: delete server using the object id so you don't need as many inputs to delete it.
      delete_cluster_member(cluster_name, server_name, server_node, session_replication) if server_exists?(server_node, server_name) && member?(cluster_name, server_name)
      save_config
      # if no more cluster members, delete cluster so it can be recreated with new template
      # delete_cluster(cluster_name) unless get_cluster_members(cluster_name).count > 0
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
    end
  end
end
