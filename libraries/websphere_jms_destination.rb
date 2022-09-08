#
# Cookbook:: websphere
# Resource:: websphere_jms_destination
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_base'

module WebsphereCookbook
  class WebsphereJmsDestination < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_jms_destination
    provides :websphere_jms_destination
    property :jms_dest_name, String, name_property: true
    property :jndi_name, String, required: true
    property :ext_jndi_name, String, required: true
    property :scope, String, required: true # eg 'Cell=MyCell,Cluster=MyCluster'
    property :jms_provider, String, required: true
    property :type, String, required: true, regex: /^(QUEUE|TOPIC|UNIFIED)$/
    property :description, [String, nil]
    property :category, [String, nil]

    action :create do
      unless jms_dest_exists?
        cmd = "AdminJMS.createGenericJMSDestinationAtScope('#{new_resource.scope}', '#{new_resource.jms_provider}', "\
          "'#{new_resource.jms_dest_name}',  '#{new_resource.jndi_name}', '#{new_resource.ext_jndi_name}', [['type', '#{new_resource.type}']"
        cmd << ", ['description', '#{new_resource.description}']" if new_resource.description
        cmd << ", ['category', '#{new_resource.category}']" if new_resource.category
        cmd << '])'

        wsadmin_exec("Create JMS destination #{new_resource.jms_dest_name} #{new_resource.type}", cmd)
      end
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def jms_dest_exists?
        cmd = "-c \"AdminJMS.listGenericJMSDestinations('#{new_resource.jms_dest_name}')\""
        mycmd = wsadmin_returns(cmd)
        return true if mycmd.stdout.include?("#{new_resource.jms_dest_name}\(")
        false
      end
    end
  end
end
