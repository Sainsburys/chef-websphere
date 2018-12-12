
require_relative 'websphere_cluster'

module WebsphereCookbook
  class WebsphereClusterMember < WebsphereCluster
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_cluster_member
    property :server_name, String, name_property: true
    property :server_node, [String, nil], default: nil, required: true
    property :member_weight, Integer, default: 2 # number from 0-100. Higher weight gets more traffic
    property :session_replication, [TrueClass, FalseClass], default: false
    property :resources_scope, String, default: 'both', regex: /^(both|server|cluster)$/
    property :generate_unique_ports, [TrueClass, FalseClass], default: true
    property :attributes, [Hash, nil], default: nil
    property :template_node_name, [String, nil], default: nil, required: false
    property :template_server_name, [String, nil], default: nil, required: false

    # creates a new profile or augments/updates if profile exists.
    action :create do
      # make sure cluster exists, and we're not adding a server that already exists in a cluster.
      if cluster_exists?(new_resource.cluster_name) && !member?(new_resource.cluster_name, new_resource.server_name, new_resource.server_node)
        if get_cluster_members(new_resource.cluster_name).count > 0
          # this will NOT be the first member (or we have defined a template at some point). Add as additional
          # There is a horrible WAS 'feature' that means that even if a template has been defined on a cluster, if there are no members
          # in it, then when you add a new JVM WAS takes this as a new template with the default application profile.
          Chef::Log.info('Not creating first member, either existing members or templates exist')
          cmd = "AdminTask.createClusterMember(['-clusterName', '#{new_resource.cluster_name}',"\
            " '-memberConfig', '[-memberNode #{new_resource.server_node} -memberName #{new_resource.server_name}"\
            " -memberWeight #{new_resource.member_weight} -genUniquePorts #{new_resource.generate_unique_ports}"\
            " -replicatorEntry #{new_resource.session_replication}]'])"
          wsadmin_exec(
            "wsadmin add additional member: #{new_resource.server_name} to cluster: #{new_resource.cluster_name} ",
            cmd
          )
        else
          # this will be the first member and be the template for further cluster members. Decide if we have a template server elsewhere to use
          Chef::Log.info('Creating first cluster member and template')
          cmd = nil
          if !new_resource.template_node_name.nil? && !new_resource.template_server_name.nil?
            Chef::Log.info("Using node #{new_resource.template_node_name} and server #{new_resource.template_server_name} as a template")
            cmd = "AdminClusterManagement.createFirstClusterMemberWithTemplateNodeServer('#{new_resource.cluster_name}',"\
              " '#{new_resource.server_node}', '#{new_resource.server_name}', '#{new_resource.template_node_name}',"\
              " '#{new_resource.template_server_name}')"
          else
            # This will create a standard WAS server using the default application server template
            Chef::Log.info('Creating new member using default application server template')
            cmd = "AdminClusterManagement.createFirstClusterMemberWithTemplate('#{new_resource.cluster_name}',"\
              " '#{new_resource.server_node}', '#{new_resource.server_name}', 'default')"
          end
          wsadmin_exec("wsadmin add first cluster member: #{new_resource.server_name} to cluster: #{new_resource.cluster_name} ", cmd)
        end
      end

      # set attributes on server
      ruby_block 'set clustered server attributes' do
        block do
          server_id = get_id("/Node:#{new_resource.server_node}/Server:#{new_resource.server_name}/")
          update_attributes(new_resource.attributes, server_id) if !server_id.nil? && new_resource.attributes
        end
        action :run
      end
      node.default['websphere']['endpoints'] = get_ports
      # Chef::Log.debug("endpoints set #{node['websphere']['endpoints'][server_node][server_name]}")
      save_config
    end

    action :start do
      # it can take a minute to create the clustered server, so we need to add a delay in if it cannot find it.
      sleep(30) if !server_exists?(new_resource.server_node, new_resource.server_name) || !member?(new_resource.cluster_name, new_resource.server_name)
      sleep(30) if !server_exists?(new_resource.server_node, new_resource.server_name) || !member?(new_resource.cluster_name, new_resource.server_name)
      return unless server_exists?(new_resource.server_node, new_resource.server_name) || member?(new_resource.cluster_name, new_resource.server_name, new_resource.server_node)
      start_server(new_resource.cluster_name, new_resource.server_name, new_resource.server_node)
      node.default['websphere']['endpoints'] = get_ports
      # Chef::Log.debug("endpoints set #{node['websphere']['endpoints'][server_node][server_name]}")
    end

    action :delete do
      # TODO: delete server using the object id so you don't need as many inputs to delete it.
      return unless server_exists?(new_resource.server_node, new_resource.server_name) && member?(new_resource.cluster_name, new_resource.server_name, new_resource.server_node)
      delete_cluster_member(
        new_resource.cluster_name,
        new_resource.server_name,
        new_resource.server_node,
        new_resource.session_replication
      )
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
