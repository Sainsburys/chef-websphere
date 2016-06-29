#
# Cookbook Name:: websphere
# Resource:: websphere-server
#
# Copyright (C) 2015 J Sainsburys
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
  class WebsphereJms < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_jms_provider
    property :provider_name, String, name_property: true
    property :scope, [String, nil], default: nil, required: true # eg 'Cell=Cell1'
    property :context_factory, [String, nil], default: nil
    property :url, [String, nil], default: nil
    property :classpath_jars, Array, default: nil # full path to each jar
    property :description, [String, nil], default: nil

    action :create do
      cmd = "AdminJMS.createJMSProviderAtScope('#{scope}', '#{provider_name}', "\
        "'#{context_factory}', '#{url}', [['classpath', '#{classpath_jars.join(';')}'], ['description', '#{description}']])"

      wsadmin_exec("Create JMS Provider #{provider_name}", cmd)
    end

    action :delete do
      # TODO:
    end

  end
end
