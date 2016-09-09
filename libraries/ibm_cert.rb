#
# Cookbook Name:: websphere
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

module WebsphereCookbook
  class WebsphereKdb < Chef::Resource

    resource_name :ibm_cert
    property :label, String, name_property: true
    property :dn, String, required: true # eg "CN=mydomain.com,O=MyOrg,C=UK"
    property :kdb, String, required: true, regex: /.*(\.kdb|\.p12)/ # path to keystore file. Will create if it doesn't exist. File must end in .kdb or .p12
    property :kdb_password, String, required: true
    property :algorithm, String, default: 'SHA256WithRSA'
    property :size, String, default: '2048', regex: /^(2048|1024|512)$/
    property :expire, String, default: '3600', required: true
    property :extract_to, String, default: lazy { "#{::File.dirname(kdb)}/#{label}.cer" } # used by the extract action only. extracts to given file in ascii format
    property :add_cert, [String, nil], default: nil # path to certificate to add to kdb, only used in add.
    property :default_cert, String, default: 'no', regex: /^(yes|no)$/
    property :ikeycmd, String, default: lazy { "#{websphere_root}/java/jre/bin/ikeycmd" }
    property :owned_by, String, default: 'root'
    property :sensitive_exec, [TrueClass, FalseClass], default: true # for debug purposes

    action :create do

      create_kdb
      cmd = "#{ikeycmd} -cert -create -db #{kdb} -pw #{kdb_password} -sig_alg #{algorithm} -size #{size} "\
        "-expire #{expire} -dn #{dn} -label #{label} -default_cert #{default_cert}"

      execute "create cert #{label}" do
        command cmd
        sensitive sensitive_exec
        action :run
        returns [0, 22]
      end

      set_perms

    end

    action :extract do
      cmd = "#{ikeycmd} -cert -extract -db #{kdb} -pw #{kdb_password} -label #{label} -target #{extract_to} -format ascii"

      execute "extract cert #{label}" do
        command cmd
        sensitive sensitive_exec
        action :run
        creates extract_to
        only_if { ::File.exist?(kdb) }
      end

      set_perms
    end

    action :add do

      execute "add cert #{label} to #{kdb}" do
        command "#{ikeycmd} -cert -add -pw #{kdb_password} -label #{label} -trust enable -file #{add_cert} -db #{kdb}"
        sensitive sensitive_exec
        action :run
        only_if { ::File.exist?(kdb) && ::File.exist?(add_cert) }
      end
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do

      def create_kdb
        dir = ::File.dirname(kdb)

        directory dir do
          recursive true
          mode 0600
          owner owned_by
          action :create
        end

        execute "create kdb #{kdb}" do
          command "#{ikeycmd} -keydb -create -db #{kdb} -pw #{kdb_password} -type cms -expire 7300 -stash"
          sensitive sensitive_exec
          action :run
          creates kdb
        end
      end

      def set_perms
        root_dir = ::File.dirname(kdb)
        execute "set perms" do
          cwd root_dir
          command "chown #{owned_by} #{root_dir}/* && chmod 600 #{root_dir}/*"
        end
      end

    end
  end
end
