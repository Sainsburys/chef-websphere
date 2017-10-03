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
    property :attributes, [Hash, nil], default: { } # Generic hash holding attributes for the provider - see : https://www.ibm.com/support/knowledgecenter/en/SS7K4U_7.0.0/com.ibm.websphere.zseries.doc/info/zseries/ae/rxml_7adminjms.html (ignore that it's for zOS) 
    action :create do
      unless jms_provider_exists?
        @jmsattrs = attributes.merge( {'classpath' => "#{classpath_jars.join(';')}" } )
        @jmsattrs.merge!( {'description' => "#{description}" } )
        @attributes_str = attributes_to_wsadmin_str(@jmsattrs)
        cmd = "AdminJMS.createJMSProviderAtScope('#{scope}', '#{provider_name}', "\
          "'#{context_factory}', '#{url}', #{@attributes_str})"

        wsadmin_exec("Create JMS Provider #{provider_name}", cmd)
      end
    end
    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def jms_provider_exists?
        cmd = "-c \"AdminJMS.listJMSProviders('#{provider_name}')\""
        mycmd = wsadmin_returns(cmd)
        return true if mycmd.stdout.include?("#{provider_name}\(")
        false
      end
    end
  end
end
