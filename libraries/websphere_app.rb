#
# Cookbook Name:: websphere
# Resource:: websphere_app
#
# Copyright (C) 2015-2019 J Sainsburys
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
      unless get_id("/Deployment:#{new_resource.app_name}/")
        deploy_to_cluster(
          new_resource.app_name,
          new_resource.app_file,
          new_resource.cluster_name,
          "[['.*', '.*', 'default_host']]"
        )
        sleep 20
      end
    end

    action :deploy_to_server do
      unless get_id("/Deployment:#{new_resource.app_name}/")
        cmd = "AdminApp.install('#{new_resource.app_file}', ['-appname', '#{new_resource.app_name}',"\
          " '-node', '#{new_resource.node_name}', '-server', '#{new_resource.server_name}', '-MapWebModToVH', [['.*', '.*', 'default_host']]"
        cmd << ", '-contextroot', '/'" if new_resource.context_root
        cmd << '])'
        wsadmin_exec(
          "install application #{new_resource.app_name} to server #{new_resource.server_name}",
          cmd,
          [0]
        )
        sleep 20
      end
    end

    action :remove do
    end

    action :start do
      # TODO: find a way to check if app is already running, instead of allowing 103 return code.
      # give time for app to deploy
      1.upto(8) do |_n|
        sleep 20
        break if get_id("/Deployment:#{new_resource.app_name}/")
      end
      if get_id("/Deployment:#{new_resource.app_name}/")
        cmd = "AdminApplication.startApplicationOnAllDeployedTargets('#{new_resource.app_name}', '#{new_resource.node_name}')"
        cmd = "AdminApplication.startApplicationOnCluster('#{new_resource.app_name}', '#{new_resource.cluster_name}')" if new_resource.cluster_name
        wsadmin_exec("start application #{new_resource.app_name}", cmd, [0, 103])
      else
        Chef::Log.warn("Unable to start application #{new_resource.app_name}. It does NOT exist.")
      end
    end

    action :stop do
      # give time for app to deploy
      1.upto(8) do |_n|
        sleep 20
        break if get_id("/Deployment:#{new_resource.app_name}/")
      end
      # TODO: find a way to check if app is already stopped, instead of allowing 103 return code.
      if get_id("/Deployment:#{new_resource.app_name}/")
        cmd = "AdminApplication.stopApplicationOnAllDeployedTargets('#{new_resource.app_name}', '#{new_resource.node_name}')"
        cmd = "AdminApplication.stopApplicationOnCluster('#{new_resource.app_name}', '#{new_resource.cluster_name}')" if new_resource.cluster_name
        wsadmin_exec("stop application #{new_resource.app_name}", cmd, [0, 103])
      else
        Chef::Log.warn("Unable to stop application #{new_resource.app_name}. It does NOT exist.")
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
