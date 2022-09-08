#
# Cookbook:: websphere
# Resource:: websphere_env
# Copyright:: 2015-2022 J Sainsburys
# License:: Apache License, Version 2.0

require_relative 'websphere_base'

module WebsphereCookbook
  class WebsphereEnv < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_env
    provides :websphere_env
    property :variable_name, String, name_property: true
    property :scope, String, required: true # eg 'Cell=Cell1'
    property :value, [String, nil]

    action :set do
      cmd = "AdminTask.setVariable('[ -scope #{new_resource.scope} "\
        "-variableName \\'#{new_resource.variable_name}\\' -variableValue \\'#{new_resource.value}\\']')"
      wsadmin_exec("Set websphere env variable #{new_resource.variable_name}", cmd)
    end

    action :remove do
      cmd = "AdminTask.removeVariable('[ -scope #{new_resource.scope} -variableName \\'#{new_resource.variable_name}\\']')"
      wsadmin_exec("Remove websphere env variable #{new_resource.variable_name}", cmd)
    end
  end
end
