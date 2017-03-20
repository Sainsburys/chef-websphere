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

    # Return the last line of a wsadmin cmd output.
    # Useful when trying to get a single value from a wsadmin cmd. By example if we want to get "server1" from:
    # AdminConfig.showAttribute(serverId, 'memberName')
    # WASX7209I: Connected to process "dmgr" on node infradev-test-gol-dmgr-i-0869602ce0cc48ce6 using SOAP connector;  The type of process is: DeploymentManager
    # 'server1'
    def wsadmin_last_returned_value(output)
      output.lines.last.chomp.match(/^'(.*)'$/).captures.first
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
  end
end
