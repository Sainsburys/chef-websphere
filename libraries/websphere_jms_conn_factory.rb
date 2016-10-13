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
  class WebsphereJmsConnFactory < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_jms_conn_factory
    property :conn_factory_name, String, name_property: true
    property :scope, String, required: true # eg 'Cell=MyCell,Cluster=MyCluster'
    property :jndi_name, String, required: true
    property :ext_jndi_name, String, required: true
    property :jms_provider, String, required: true
    property :type, String, required: true, regex: /^(QUEUE|TOPIC|UNIFIED)$/
    property :description, [String, nil], default: nil
    property :category, [String, nil], default: nil
    property :conn_pool_timeout, String, default: '180'
    property :conn_pool_min, String, default: '1'
    property :conn_pool_max, String, default: '10'
    property :conn_pool_reap_time, String, default: '180'
    property :conn_pool_unused_timeout, String, default: '1800'
    property :conn_aged_timeout, String, default: '0'
    property :conn_purge_policy, String, default: 'FailingConnectionOnly', regex: /^(FailingConnectionOnly|EntirePool)$/

    # AdminJMS.createGenericJMSConnectionFactoryAtScope("Cell="+cellname+",Cluster="+clustername+"", "WebMethodsUMProvider",
    # "QueueConnectionFactory", "QueueConnectionFactory", "Identity_CF",
    # [['type','QUEUE'],['connectionPool',[['connectionTimeout','180'],['maxConnections','10'],['minConnections','1'],
    #  ['reapTime','180'],['unusedTimeout','1800'],['agedTimeout','0'],['purgePolicy','FailingConnectionOnly']]]])

    action :create do
      unless jms_conn_factory_exists?
        cmd = "AdminJMS.createGenericJMSConnectionFactoryAtScope('#{scope}', "\
          "'#{jms_provider}',  '#{conn_factory_name}', '#{jndi_name}', '#{ext_jndi_name}', [['type', '#{type}']"
        cmd << ", ['connectionPool', [['connectionTimeout','#{conn_pool_timeout}'],['maxConnections','#{conn_pool_max}'],['minConnections','#{conn_pool_min}'],"\
          "['reapTime','#{conn_pool_reap_time}'],['unusedTimeout','#{conn_pool_unused_timeout}'],['agedTimeout','#{conn_aged_timeout}'],['purgePolicy','#{conn_purge_policy}']]]"
        cmd << ", ['connectionPool', '#{description}']" if description
        cmd << ", ['category', '#{category}']" if category
        cmd << '])'

        wsadmin_exec("Create JMS connection factory #{conn_factory_name}", cmd)
      end
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def jms_conn_factory_exists?
        cmd = "-c \"AdminJMS.listGenericJMSConnectionFactories('#{conn_factory_name}')\""
        mycmd = wsadmin_returns(cmd)
        return true if mycmd.stdout.include?("#{conn_factory_name}\(")
        false
      end
    end
  end
end
