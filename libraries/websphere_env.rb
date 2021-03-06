#
# Cookbook:: websphere
# Resource:: websphere_env
#
# Copyright:: 2015-2021 J Sainsburys
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'websphere_base'

module WebsphereCookbook
  class WebsphereEnv < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_env
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
