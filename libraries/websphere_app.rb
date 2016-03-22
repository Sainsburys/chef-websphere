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
  class WebsphereApplication < WebsphereBase
    require_relative 'helpers'
    include WebsphereHelpers

    resource_name :websphere_app
    property :app_name, String, name_property: true
    property :app_file, [String, nil], default: nil, required: true
    property :server_name, [String, nil], default: nil
    property :node_name, [String, nil], default: nil
    property :cluster_name, [String, nil], default: nil
    property :context_root, [String, nil], default: nil

    # TODO: Add support for web server and add save functionality
    # If you want to deploy an application and specify the HTTP server during the deployment so that the application
    # will appear in the generated plugin-cfg.xml file, you must first install the application with a target of -cluster.
    # After you install the application and before you save, use the edit command of the AdminApp object to add the additional mapping to the web server.
    # creates an empty cluster
    action :deploy_to_cluster do
      unless get_id("/Deployment:#{app_name}/")
        deploy_to_cluster(app_name, app_file, cluster_name, "[['.*', '.*', 'default_host']]")
      end
    end

    action :deploy_to_server do
      unless get_id("/Deployment:#{app_name}/")
        cmd = "AdminApp.install('#{app_file}', ['-appname', '#{app_name}', '-node', '#{node_name}', '-server', '#{server_name}', '-MapWebModToVH', [['.*', '.*', 'default_host']]"
        cmd << ", '-contextroot', '/'" if context_root
        # cmd << ", '-nodeployejb', '-nopreCompileJSPs', '-nouseMetaDataFromBinary' "
        cmd << '])'
        wsadmin_exec("install application #{app_name} to server #{server_name}", cmd)
      end
    end

    action :remove do
    end

    action :start do
      # TODO: find a way to check if app is already running, instead of allowing 103 return code.
      if get_id("/Deployment:#{app_name}/")
        cmd = "AdminApplication.startApplicationOnAllDeployedTargets('#{app_name}', '#{node_name}')"
        cmd = "AdminApplication.startApplicationOnCluster('#{app_name}', '#{cluster_name}')" if cluster_name
        wsadmin_exec("start application #{app_name}", cmd, [0, 103])
      else
        Chef::Log.warn("Unable to start application #{app_name}. It does NOT exist.")
      end
    end

    action :stop do
      # TODO: find a way to check if app is already stopped, instead of allowing 103 return code.
      if get_id("/Deployment:#{app_name}/")
        cmd = "AdminApplication.stopApplicationOnAllDeployedTargets('#{app_name}', '#{node_name}')"
        cmd = "AdminApplication.stopApplicationOnCluster('#{app_name}', '#{cluster_name}')" if cluster_name
        wsadmin_exec("stop application #{app_name}", cmd, [0, 103])
      else
        Chef::Log.warn("Unable to stop application #{app_name}. It does NOT exist.")
      end
    end

    action :update do
    end

    action :rollout_update do
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
    end
  end
end
