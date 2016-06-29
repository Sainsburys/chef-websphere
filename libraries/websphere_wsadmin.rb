
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
  class WebsphereWsadmin < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_wsadmin
    property :label, String, name_property: true # just a label to make the execue resource name unique
    property :script, [String, nil], default: nil
    property :file, [String, nil], default: nil
    property :return_codes, Array, default: [0]
    property :sensitive, [TrueClass, FalseClass], default: false

    action :run do

      wsadmin_cmd = './wsadmin.sh -lang jython -conntype SOAP '
      wsadmin_cmd << "-host #{dmgr_host} " if dmgr_host
      wsadmin_cmd << "-port #{dmgr_port} " if dmgr_port
      wsadmin_cmd << "-user #{admin_user} -password #{admin_password} " if admin_user && admin_password
      wsadmin_cmd << "-f \"#{file}\"" if file
      wsadmin_cmd << "-c \"#{script}\"" if script && file.nil?

      execute "wsadmin #{label}" do
        cwd bin_dir
        command wsadmin_cmd
        returns return_codes
        sensitive sensitive
        action :run
      end
    end

    action :save do
      wsadmin_cmd = './wsadmin.sh -lang jython -conntype SOAP '
      wsadmin_cmd << "-host #{dmgr_host} " if dmgr_host
      wsadmin_cmd << "-port #{dmgr_port} " if dmgr_port
      wsadmin_cmd << "-user #{admin_user} -password #{admin_password} " if admin_user && admin_password
      wsadmin_cmd << "-c \"AdminConfig.save()\""

      execute "wsadmin #{label}" do
        cwd bin_dir
        command wsadmin_cmd
        sensitive true
        action :run
      end
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do


    end
  end
end
