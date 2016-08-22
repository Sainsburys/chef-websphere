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
  class WebsphereJmsProvider < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_jms_provider
    property :provider_name, String, name_property: true
    property :scope, String, required: true # eg 'Cell=Cell1'
    property :context_factory, [String, nil], default: nil
    property :url, [String, nil], default: nil
    property :classpath_jars, [Array, nil], default: nil # full path to each jar
    property :description, [String, nil], default: nil

    action :create do
      unless jms_provider_exists?(provider_name)
        cmd = "AdminJMS.createJMSProviderAtScope('#{scope}', '#{provider_name}', "\
          "'#{context_factory}', '#{url}', [['classpath', '#{classpath_jars.join(';')}'], ['description', '#{description}']])"

          wsadmin_exec("Create JMS Provider #{provider_name}", cmd)
      end
    end

    action :delete do
      # TODO:
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do

      def jms_provider_exists?(provider_name)
        cmd = "-c \"AdminJMS.listJMSProviders('#{provider_name}')\""
        mycmd = wsadmin_returns(cmd)
        return true if mycmd.stdout.include?("\[\'#{provider_name}")
        false
      end

    end
  end
end
