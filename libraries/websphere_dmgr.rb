#
# Cookbook:: websphere
# Resource:: websphere_dmgr
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
  class WebsphereDmgr < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_dmgr

    property :label, String, name_property: true
    property :profile_name, String, required: true
    property :profile_path, String, default: lazy { "#{websphere_root}/profiles/#{profile_name}" }
    property :node_name, String, default: lazy { "#{profile_name}_node" }
    property :cell_name, [String, nil]
    property :profile_templates_dir, String, default: lazy { "#{websphere_root}/profileTemplates" }
    property :java_sdk, [String, nil] # javasdk version must be already be installed using ibm-installmgr cookbook. If none is specified the embedded default is used
    property :security_attributes, [Hash, nil] # these are set when the Dmgr is started
    property :manage_user, [true, false], default: true
    property :profile_env, [Hash, nil] # start/stop environment parameters

    # creates a new profile or augments/updates if profile exists.
    action :create do
      create_service_account(new_resource.run_user, new_resource.run_group) unless new_resource.run_user == 'root' || new_resource.manage_user == false

      p_exists = profile_exists?(new_resource.profile_name)
      unless p_exists
        template_path = template_lookup('dmgr', new_resource.profile_templates_dir)
        management_type = management_type_lookup('dmgr')

        options = " -profileName #{new_resource.profile_name} -profilePath #{new_resource.profile_path} "\
          "-templatePath #{template_path} -nodeName #{new_resource.node_name}"
        options << " -cellName #{new_resource.cell_name}" if new_resource.cell_name
        options << " -serverType #{management_type}"
        options << " -adminUserName #{new_resource.admin_user} -adminPassword #{new_resource.admin_password} -enableAdminSecurity true" if new_resource.admin_user
        manageprofiles_exec('export DisableWASDesktopIntegration=false && ./manageprofiles.sh -create', options)
      end

      # Enable "profile_name" to use the specific "java_sdk"
      if new_resource.java_sdk
        current_java = current_java_sdk(new_resource.profile_name)
        enable_java_sdk(new_resource.java_sdk, "#{new_resource.profile_path}/bin", new_resource.profile_name) if p_exists && current_java != new_resource.java_sdk
      end

      # run dmgr as service
      # no need to do user things (if you installed was out of this cookbook by example)
      enable_as_service(new_resource.profile_name, 'dmgr', new_resource.profile_path, new_resource.run_user)
    end

    action :start do
      start_manager(new_resource.profile_name, new_resource.profile_env, "#{new_resource.profile_path}/bin")

      # set attributes on dmgr
      ruby_block 'set security attributes' do
        block do
          object_id = get_id('/Security:/')
          update_attributes(new_resource.security_attributes, object_id)
        end
        action :run
        only_if { new_resource.security_attributes }
      end
    end

    action :stop do
      service new_resource.node_name do
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
