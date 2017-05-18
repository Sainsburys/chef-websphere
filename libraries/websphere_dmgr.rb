
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
  class WebsphereDmgr < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_dmgr

    property :profile_name, String, name_property: true
    property :profile_path, String, default: lazy { "#{websphere_root}/profiles/#{profile_name}" }
    property :node_name, String, default: lazy { "#{profile_name}_node" }
    property :cell_name, [String, nil], default: nil
    property :profile_templates_dir, String, default: lazy { "#{websphere_root}/profileTemplates" }
    property :java_sdk, [String, nil], default: nil # javasdk version must be already be installed using ibm-installmgr cookbook. If none is specified the embedded default is used
    property :security_attributes, [Hash, nil], default: nil # these are set when the Dmgr is started
    property :run_user, String, default: 'was'
    property :run_group, String, default: 'was'
    property :manage_user, [TrueClass, FalseClass], default: true

    # creates a new profile or augments/updates if profile exists.
    action :create do
      unless run_user == 'root' || manage_user == false
        create_service_account(run_user, run_group)
      end

      p_exists = profile_exists?(profile_name)
      unless p_exists
        template_path = template_lookup('dmgr', profile_templates_dir)
        management_type = management_type_lookup('dmgr')

        options = " -profileName #{profile_name} -profilePath #{profile_path} -templatePath #{template_path} "\
        "-nodeName #{node_name}"
        options << " -cellName #{cell_name}" if cell_name
        options << " -serverType #{management_type}"
        options << " -adminUserName #{admin_user} -adminPassword #{admin_password} -enableAdminSecurity true" if admin_user
        manageprofiles_exec('./manageprofiles.sh -create', options)
      end

      # Enable "profile_name" to use the specific "java_sdk"
      if java_sdk
        current_java = current_java_sdk(profile_name)
        enable_java_sdk(java_sdk, "#{profile_path}/bin", profile_name) if p_exists && current_java != java_sdk
      end

      # run dmgr as service
      # no need to do user things (if you installed was out of this cookbook by example)
      enable_as_service(profile_name, 'dmgr', profile_path, run_user)
    end

    action :start do
      # service node_name do
      #   action :start
      # end
      # start_profile(profile_name, bin_dir, "./startManager.sh -profileName #{profile_name}", [0, 255])
      start_manager(profile_name)

      # set attributes on dmgr
      ruby_block 'set security attributes' do
        block do
          object_id = get_id('/Security:/')
          update_attributes(security_attributes, object_id)
        end
        action :run
        only_if { security_attributes }
      end
    end

    action :stop do
      service node_name do
        action :stop
      end
    end

    action :sync_all do
      # syncs all nodes without restarting nodeagent or servers
      sync_node_wsadmin('all')
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
    end
  end
end
