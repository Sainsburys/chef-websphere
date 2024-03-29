#
# Cookbook:: websphere
# Resource:: websphere_jms_provider
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_base'

module WebsphereCookbook
  class WebsphereJmsProvider < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_jms_provider
    provides :websphere_jms_provider
    property :provider_name, String, name_property: true
    property :scope, String, required: true # eg 'Cell=Cell1'
    property :context_factory, [String, nil]
    property :url, [String, nil]
    property :classpath_jars, [Array, nil] # full path to each jar
    property :description, [String, nil]
    property :attributes, [Hash, nil], default: {} # Generic hash holding attributes for the provider - see : https://www.ibm.com/support/knowledgecenter/en/SS7K4U_7.0.0/com.ibm.websphere.zseries.doc/info/zseries/ae/rxml_7adminjms.html (ignore that it's for zOS)
    action :create do
      unless jms_provider_exists?
        @jmsattrs = new_resource.attributes.merge('classpath' => new_resource.classpath_jars.join(';').to_s)
        @jmsattrs['description'] = new_resource.description
        @attributes_str = attributes_to_wsadmin_str(@jmsattrs)
        cmd = "AdminJMS.createJMSProviderAtScope('#{new_resource.scope}', '#{new_resource.provider_name}', "\
          "'#{new_resource.context_factory}', '#{new_resource.url}', #{@attributes_str})"

        wsadmin_exec("Create JMS Provider #{new_resource.provider_name}", cmd)
      end
    end
    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def jms_provider_exists?
        cmd = "-c \"AdminJMS.listJMSProviders('#{new_resource.provider_name}')\""
        mycmd = wsadmin_returns(cmd)
        return true if mycmd.stdout.include?("#{new_resource.provider_name}\(")
        false
      end
    end
  end
end
