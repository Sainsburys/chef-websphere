#
# Cookbook:: websphere
# Resource:: websphere_cluster
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_base'

module WebsphereCookbook
  class WebsphereCluster < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_cluster
    provides :websphere_cluster
    property :cluster_name, String, name_property: true
    property :prefer_local, [true, false], default: true
    property :cluster_type, String, default: 'APPLICATION_SERVER', regex: /^(APPLICATION_SERVER|PROXY_SERVER)$/

    # creates an empty cluster
    action :create do
      unless cluster_exists?(new_resource.cluster_name)
        cmd = "AdminClusterManagement.createClusterWithoutMember('#{new_resource.cluster_name}')"
        wsadmin_exec("createClusterWithoutMember #{new_resource.cluster_name}", cmd)
        save_config
      end
    end

    action :delete do
      delete_cluster(new_resource.cluster_name) if cluster_exists?(new_resource.cluster_name)
      save_config
    end

    action :ripple_start do
      cmd = "AdminClusterManagement.rippleStartSingleCluster('#{new_resource.cluster_name}')"
      wsadmin_exec("ripple_restart cluster: #{new_resource.cluster_name} ", cmd, [0, 103])
    end

    action :start do
      cmd = "AdminClusterManagement.startSingleCluster('#{new_resource.cluster_name}')"
      wsadmin_exec("start cluster: #{new_resource.cluster_name} ", cmd, [0, 103])
    end

    action :stop do
      cmd = "AdminClusterManagement.stopSingleCluster('#{new_resource.cluster_name}')"
      wsadmin_exec("stop cluster: #{new_resource.cluster_name} ", cmd, [0, 103])
    end
  end
end
