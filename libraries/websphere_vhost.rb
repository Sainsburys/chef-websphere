#
# Cookbook:: websphere
# Resource:: websphere_vhost
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_base'

module WebsphereCookbook
  class WebsphereHostAlias < WebsphereBase
    resource_name :websphere_vhost_alias
    provides :websphere_vhost_alias
    property :vhost_name, String, required: true
    property :alias_host, String, required: true # eg 'Cell=Cell1'
    property :alias_port, String, required: true

    action :create do
      vhost_alias('add_alias', new_resource.vhost_name, new_resource.alias_host, new_resource.alias_port)
    end

    action :delete do
      vhost_alias('remove_alias', new_resource.vhost_name, new_resource.alias_host, new_resource.alias_port)
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def vhost_alias(action_to_take, vhost_name, alias_host, alias_port, bin_directory = '/opt/IBM/WebSphere/AppServer/bin')
        cookbook_file "#{bin_directory}/virtual_host_alias.py" do
          cookbook 'websphere'
          source 'virtual_host_alias.py'
          mode '0755'
          action :create
        end

        cmd = "#{bin_directory}/virtual_host_alias.py #{action_to_take} '#{vhost_name}' '#{alias_host}' #{alias_port}"
        wsadmin_exec_file("wsadmin #{action_to_take} virtual host alias to #{vhost_name}", cmd, [0])
      end
    end
  end
end
