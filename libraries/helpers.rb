module WebsphereCookbook
  module WebsphereHelpers
    def current_java_sdk(profile_name)
      cmd = "./managesdk.sh -listEnabledProfile -profileName #{profile_name}"
      mycmd = Mixlib::ShellOut.new(cmd, cwd: bin_dir)
      mycmd.run_command
      return ' ' if mycmd.error?
      str = mycmd.stdout.match(/PROFILE_COMMAND_SDK = (.*) \n/).captures.first
      return ' ' if str.nil?
      Chef::Log.debug("profile: #{profile_name} is running Java #{str}")
      str
    end

    def str_array?(str)
      str.strip!
      return true if str.start_with?('[') && str.end_with?(']')
      false
    end

    def str_to_array(str)
      str.chomp.gsub(/\[|\]/, '').split(', ') # trim '[' and ']' chars from string and convert to array
    end

    # returns cell name for a profile path
    # assumes only one cell folder can exist in a profile config path
    def profile_cell(p_path)
      ::Dir.chdir("#{p_path}/config/cells")
      cell = ::Dir.glob('*').select { |f| ::File.directory? f }
      cell.first
    end

    def template_lookup(profle_type, profile_templates_dir)
      templates = {
        'appserver' => "#{profile_templates_dir}/default",
        'dmgr' => "#{profile_templates_dir}/management",
        'job' => "#{profile_templates_dir}/management",
        'custom' => "#{profile_templates_dir}/managed"
      }
      templates[profle_type]
    end

    def management_type_lookup(profle_type)
      mgmttype = {
        'dmgr' => 'DEPLOYMENT_MANAGER',
        'job' => 'JOB_MANAGER'
      }
      mgmttype[profle_type]
    end
# Convert a passed in hash into a wsadmin acceptable string
    def attributes_to_wsadmin_str(attributes_hash)
      if !attributes_hash.nil
        attribute_str = '['
        attributes_hash.each do |k, v|
          attribute_str.concat("['#{k}', ")
          if v.is_a?(Hash)
            attribute_str.concat(attributes_to_wsadmin_str(v))
          else
            attribute_str.concat("'#{v}']")
          end
        end
        attribute_str.concat(']')
        attribute_str
      end
  end
end
