#
# Cookbook:: websphere
# Resource:: websphere_cluster_member
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_cluster'

module WebsphereCookbook
  class WebsphereClusterMember < WebsphereCluster
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_cluster_member
    provides :websphere_cluster_member
    property :server_name, String, name_property: true
    property :server_names, [Array, nil], required: false
    property :server_node, [String, nil], required: true
    property :member_weight, Integer, default: 2 # number from 0-100. Higher weight gets more traffic
    property :session_replication, [true, false], default: false
    property :resources_scope, String, default: 'both', regex: /^(both|server|cluster)$/
    property :generate_unique_ports, [true, false], default: true
    property :attributes, [Hash, nil]
    property :template_node_name, [String, nil], required: false
    property :template_server_name, [String, nil], required: false

    # creates a new profile or augments/updates if profile exists.
    action :create do
      if new_resource.server_names.nil?
        new_resource.server_names = [new_resource.server_name]
      end
      combined_cmd = ''
      added_servers = ''
      new_resource.server_names.each do |local_server_name|
        # make sure cluster exists, and we're not adding a server that already exists in a cluster.
        next unless cluster_exists?(new_resource.cluster_name) && !member?(new_resource.cluster_name, local_server_name, new_resource.server_node)
        if get_cluster_members(new_resource.cluster_name).count > 0
          # this will NOT be the first member (or we have defined a template at some point). Add as additional
          # There is a horrible WAS 'feature' that means that even if a template has been defined on a cluster, if there are no members
          # in it, then when you add a new JVM WAS takes this as a new template with the default application profile.
          Chef::Log.info('Not creating first member, either existing members or templates exist')
          cmd = "AdminTask.createClusterMember(['-clusterName', '#{new_resource.cluster_name}',"\
            " '-memberConfig', '[-memberNode #{new_resource.server_node} -memberName #{local_server_name}"\
            " -memberWeight #{new_resource.member_weight} -genUniquePorts #{new_resource.generate_unique_ports}"\
            " -replicatorEntry #{new_resource.session_replication}]'])"
        else
          # this will be the first member and be the template for further cluster members. Decide if we have a template server elsewhere to use
          Chef::Log.info('Creating first cluster member and template')
          cmd = nil
          if !new_resource.template_node_name.nil? && !new_resource.template_server_name.nil?
            Chef::Log.info("Using node #{new_resource.template_node_name} and server #{new_resource.template_server_name} as a template")
            cmd = "AdminClusterManagement.createFirstClusterMemberWithTemplateNodeServer('#{new_resource.cluster_name}',"\
              " '#{new_resource.server_node}', '#{local_server_name}', '#{new_resource.template_node_name}',"\
              " '#{new_resource.template_server_name}')"
          else
            # This will create a standard WAS server using the default application server template
            Chef::Log.info('Creating new member using default application server template')
            cmd = "AdminClusterManagement.createFirstClusterMemberWithTemplate('#{new_resource.cluster_name}',"\
              " '#{new_resource.server_node}', '#{local_server_name}', 'default')"
          end
        end
        combined_cmd << " -c \"#{cmd}\""
        added_servers << "#{local_server_name} "
      end
      unless combined_cmd.empty?
        wsadmin_multi_command_exec("add servers #{added_servers} to cluster: #{new_resource.cluster_name}", combined_cmd)
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
      save_config
    end

    action :start do
      # it can take a minute to create the clustered server, so we need to add a delay in if it cannot find it.
      sleep(30) if !server_exists?(new_resource.server_node, new_resource.server_name) || !member?(new_resource.cluster_name, new_resource.server_name, new_resource.server_node)
      sleep(30) if !server_exists?(new_resource.server_node, new_resource.server_name) || !member?(new_resource.cluster_name, new_resource.server_name, new_resource.server_node)
      return unless server_exists?(new_resource.server_node, new_resource.server_name) || member?(new_resource.cluster_name, new_resource.server_name, new_resource.server_node)
      start_server(new_resource.cluster_name, new_resource.server_name)
      node.default['websphere']['endpoints'] = get_ports
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

    # need to wrap helper methods in class_eval so they're available in the action.
    action_class.class_eval do
    end
  end
end
