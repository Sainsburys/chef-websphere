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
  class WebsphereJmsDestination < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_jms_destination
    property :jms_dest_name, String, name_property: true
    property :jndi_name, String, required: true
    property :ext_jndi_name, String, required: true
    property :scope, String, required: true # eg 'Cell=MyCell,Cluster=MyCluster'
    property :jms_provider, String, required: true
    property :type, String, required: true, regex: /^(QUEUE|TOPIC|UNIFIED)$/
    property :description, [String, nil], default: nil
    property :category, [String, nil], default: nil

    action :create do
      unless jms_dest_exists?
        cmd = "AdminJMS.createGenericJMSDestinationAtScope('#{scope}', '#{jms_provider}', "\
          "'#{jms_dest_name}',  '#{jndi_name}', '#{ext_jndi_name}', [['type', '#{type}']"
        cmd << ", ['description', '#{description}']" if description
        cmd << ", ['category', '#{category}']" if category
        cmd << '])'

        wsadmin_exec("Create JMS destination #{jms_dest_name} #{type}", cmd)
      end
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def jms_dest_exists?
        cmd = "-c \"AdminJMS.listGenericJMSDestinations('#{jms_dest_name}')\""
        mycmd = wsadmin_returns(cmd)
        return true if mycmd.stdout.include?("#{jms_dest_name}\(")
        false
      end
    end
  end
end
