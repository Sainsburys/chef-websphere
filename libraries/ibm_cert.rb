#
# Cookbook Name:: websphere
# Resource:: ibm_cert
#
# Copyright (C) 2015-2018 J Sainsburys
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
    property :expire_kdb, String, default: '7300', required: false
    property :extract_to, String, default: lazy { "#{::File.dirname(kdb)}/#{label}.cer" } # used by the extract action only. extracts to given file in ascii format
    property :add_cert, [String, nil], default: nil # path to certificate to add/import to kdb, only used in add/import.
    property :kdb_type, String, default: 'pkcs12' # type of key database
    property :import_password, [String, nil], default: nil # password for import database, only used in import
    property :default_cert, String, default: 'no', regex: /^(yes|no)$/
    property :ikeycmd, String, default: lazy { '/opt/IBM/WebSphere/AppServer/java/jre/bin/ikeycmd' }
    property :owned_by, String, default: 'root'
    property :sensitive_exec, [TrueClass, FalseClass], default: true # for debug purposes

    action :create do
      create_kdb
      cmd = "#{new_resource.ikeycmd} -cert -create -db #{new_resource.kdb} -pw #{new_resource.kdb_password}"\
        " -sig_alg #{new_resource.algorithm} -size #{new_resource.size} -expire #{new_resource.expire}"\
        " -dn #{new_resource.dn} -label #{new_resource.label} -default_cert #{new_resource.default_cert}"

      execute "create cert #{new_resource.label}" do
        command cmd
        sensitive new_resource.sensitive_exec
        action :run
        returns [0, 22]
      end

      set_perms
    end

    action :extract do
      cmd = "#{new_resource.ikeycmd} -cert -extract -db #{new_resource.kdb} -pw #{new_resource.kdb_password}"\
        " -label #{new_resource.label} -target #{new_resource.extract_to} -format ascii"

      execute "extract cert #{new_resource.label}" do
        command cmd
        sensitive new_resource.sensitive_exec
        action :run
        creates new_resource.extract_to
        only_if { ::File.exist?(new_resource.kdb) }
      end

      set_perms
    end

    action :set_default do
      execute "set cert #{new_resource.label} as default" do
        command "#{new_resource.ikeycmd} -cert -setdefault -pw #{new_resource.kdb_password} -label #{new_resource.label} -db #{new_resource.kdb}"
        sensitive new_resource.sensitive_exec
        action :run
        only_if { cert_in_keystore? }
      end
    end

    action :add do
      execute "add cert #{new_resource.label} to #{new_resource.kdb}" do
        command "#{new_resource.ikeycmd} -cert -add -pw #{new_resource.kdb_password} -label #{new_resource.label} "\
          "-trust enable -file #{new_resource.add_cert} -db #{new_resource.kdb}"
        sensitive new_resource.sensitive_exec
        action :run
        only_if { ::File.exist?(new_resource.kdb) && ::File.exist?(new_resource.add_cert) }
        not_if { cert_in_keystore? }
      end
    end

    action :import do
      execute "import cert #{new_resource.label} to #{new_resource.kdb}" do
        command "#{new_resource.ikeycmd} -cert -import -target #{new_resource.kdb} -target_pw #{new_resource.kdb_password} "\
          "-type #{new_resource.kdb_type} -db #{new_resource.add_cert} -label #{new_resource.label} -target_type cms"
        command << " -pw #{new_resource.import_password}" if new_resource.import_password
        sensitive new_resource.sensitive_exec
        action :run
        only_if { ::File.exist?(new_resource.kdb) && ::File.exist?(new_resource.add_cert) }
        not_if { cert_in_keystore? }
      end
    end

    action :update do
      execute "remove matching cert #{new_resource.label} from #{new_resource.kdb}" do
        command "#{new_resource.ikeycmd} -cert -delete -db #{new_resource.kdb} -pw #{new_resource.kdb_password} -label #{new_resource.label}"
        sensitive new_resource.sensitive_exec
        action :run
        only_if { ::File.exist?(new_resource.kdb) && ::File.exist?(new_resource.add_cert) }
        not_if { matching_cert_in_keystore? }
        notifies :run, "execute[import cert #{new_resource.label} to #{new_resource.kdb}]", :immediately
      end

      execute "import cert #{new_resource.label} to #{new_resource.kdb}" do
        command "#{new_resource.ikeycmd} -cert -import -target #{new_resource.kdb} -target_pw #{new_resource.kdb_password} -type #{new_resource.kdb_type} -db #{new_resource.add_cert} -label #{new_resource.label} -target_type cms"
        command << " -pw #{new_resource.import_password}" if new_resource.import_password
        sensitive new_resource.sensitive_exec
        action :nothing
        only_if { ::File.exist?(new_resource.kdb) && ::File.exist?(new_resource.add_cert) }
        not_if { cert_in_keystore? }
      end
    end

    # need to wrap helper methods in class_eval
    # so they're available in the action.
    action_class.class_eval do
      def create_kdb
        dir = ::File.dirname(new_resource.kdb)

        directory dir do
          recursive true
          mode 0o600
          owner new_resource.owned_by
          action :create
        end

        execute "create kdb #{new_resource.kdb}" do
          command "#{new_resource.ikeycmd} -keydb -create -db #{new_resource.kdb} -pw #{new_resource.kdb_password} -type cms -expire #{new_resource.expire_kdb} -stash"
          sensitive new_resource.sensitive_exec
          action :run
          creates new_resource.kdb
        end
      end

      def set_perms
        root_dir = ::File.dirname(new_resource.kdb)
        execute 'set perms' do
          cwd root_dir
          command "chown #{new_resource.owned_by} #{root_dir}/* && chmod 600 #{root_dir}/*"
        end
      end

      def cert_sha256_fingerprint(db, cert_password = nil)
        cmd = "#{new_resource.ikeycmd} -cert -details -label #{new_resource.label} -db #{db}"
        cmd << " -pw #{cert_password}" if cert_password
        cmd << " | grep 'SHA256:' | awk '{print $2}'"
        mycmd = Mixlib::ShellOut.new(cmd, cwd: ::File.dirname(db))
        mycmd.run_command
        mycmd.stdout
      end

      def cert_in_keystore?
        cmd = "#{new_resource.ikeycmd} -cert -list -pw #{new_resource.kdb_password} -label #{new_resource.label} -db #{new_resource.kdb}"
        mycmd = Mixlib::ShellOut.new(cmd, cwd: ::File.dirname(new_resource.kdb))
        mycmd.run_command
        if mycmd.stdout.include?("doesn't contain an entry with label") || mycmd.error?
          Chef::Log.warn("certificate #{new_resource.label} not found in #{new_resource.kdb}")
          return false
        else
          Chef::Log.warn("certificate #{new_resource.label} already exists in #{new_resource.kdb}")
          return true
        end
      end

      # return true if the SHA256 fingerprint matches the certificate in the keystore
      def matching_cert_in_keystore?
        if cert_in_keystore?
          Chef::Log.warn("certificate #{new_resource.label} found in #{new_resource.kdb}, checking fingerprints")
          kdb_print = cert_sha256_fingerprint(new_resource.kdb, new_resource.kdb_password)
          cert_print = if new_resource.import_password
                         cert_sha256_fingerprint(new_resource.add_cert, new_resource.import_password)
                       else
                         cert_sha256_fingerprint(new_resource.add_cert)
                       end
          return true if kdb_print == cert_print
        end
        false
      end
    end
  end
end
