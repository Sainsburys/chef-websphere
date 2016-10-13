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
  class WebsphereHostAlias < WebsphereBase
    resource_name :websphere_vhost_alias
    property :vhost_name, String, required: true
    property :alias_host, String, required: true # eg 'Cell=Cell1'
    property :alias_port, String, required: true

    action :create do
      vhost_alias('add_alias', vhost_name, alias_host, alias_port)
    end

    action :delete do
      vhost_alias('remove_alias', vhost_name, alias_host, alias_port)
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def vhost_alias(action_to_take, vhost_name, alias_host, alias_port, bin_directory = '/opt/IBM/WebSphere/AppServer/bin')
        cookbook_file "#{bin_directory}/virtual_host_alias.py" do
          cookbook 'ibm-websphere'
          source 'virtual_host_alias.py'
          mode '0755'
          action :create
        end

        cmd = "#{bin_directory}/virtual_host_alias.py #{action_to_take} '#{vhost_name}' '#{alias_host}' #{alias_port}"
        wsadmin_exec_file("wsadmin #{action} virutal host alias to #{vhost_name}", cmd, [0])
      end
    end
  end
end
