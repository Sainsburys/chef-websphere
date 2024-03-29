
#
# Cookbook:: websphere
# Resource:: websphere_wsadmin
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_base'

module WebsphereCookbook
  class WebsphereWsadmin < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_wsadmin
    provides :websphere_wsadmin
    property :label, String, name_property: true # just a label to make the execue resource name unique
    property :script, [String, nil]
    property :file, [String, nil]
    property :return_codes, Array, default: [0]

    action :run do
      wsadmin_cmd = './wsadmin.sh -lang jython -conntype SOAP '
      wsadmin_cmd << "-host #{new_resource.dmgr_host} " if new_resource.dmgr_host
      wsadmin_cmd << "-port #{new_resource.dmgr_port} " if new_resource.dmgr_port
      wsadmin_cmd << "-user #{new_resource.admin_user} -password #{new_resource.admin_password} " if new_resource.admin_user && new_resource.admin_password
      wsadmin_cmd << "-f #{new_resource.file}" if new_resource.file
      wsadmin_cmd << "-c \"#{new_resource.script}\"" if new_resource.script && new_resource.file.nil?

      execute "wsadmin #{new_resource.label}" do
        cwd new_resource.bin_dir
        command wsadmin_cmd
        returns new_resource.return_codes
        sensitive new_resource.sensitive_exec
        action :run
      end
    end

    action :save do
      wsadmin_cmd = './wsadmin.sh -lang jython -conntype SOAP '
      wsadmin_cmd << "-host #{new_resource.dmgr_host} " if new_resource.dmgr_host
      wsadmin_cmd << "-port #{new_resource.dmgr_port} " if new_resource.dmgr_port
      wsadmin_cmd << "-user #{new_resource.admin_user} -password #{new_resource.admin_password} " if new_resource.admin_user && new_resource.admin_password
      wsadmin_cmd << '-c "AdminConfig.save()"'

      execute "wsadmin #{new_resource.label}" do
        cwd new_resource.bin_dir
        command wsadmin_cmd
        sensitive new_resource.sensitive_exec
        action :run
      end
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
    end
  end
end
