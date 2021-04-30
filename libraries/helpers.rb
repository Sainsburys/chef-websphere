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
      return unless ::File.exist?("#{p_path}/bin/setupCmdLine.sh")
      cell = ::File.open("#{p_path}/bin/setupCmdLine.sh").grep(/^WAS_CELL=/).first.split('=')
      cell.last.chomp
    end

    def template_lookup(profle_type, profile_templates_dir)
      templates = {
        'appserver' => "#{profile_templates_dir}/default",
        'dmgr' => "#{profile_templates_dir}/management",
        'job' => "#{profile_templates_dir}/management",
        'custom' => "#{profile_templates_dir}/managed",
      }
      templates[profle_type]
    end

    def management_type_lookup(profle_type)
      mgmttype = {
        'dmgr' => 'DEPLOYMENT_MANAGER',
        'job' => 'JOB_MANAGER',
      }
      mgmttype[profle_type]
    end

    # Generic convert to wsadmin array
    # We convert a ruby hash / array into a [] bracket string which is understood by wsadmin script.
    # Each kvp in a hash is surrounded by [] and then if the value is an object it is in-turn passed
    # through the method to ensure the correct wrapping.
    # Sample ruby input { 'foo' => [ { 'bar' => 'car', 'a' => 'b'}, {'c' => 'd', 'e' =>'f'} ] }
    #             output [['foo' [[['bar','car'],['a','b']],[['c','d'],['e','f']]]]]
    def attributes_to_wsadmin_str(an_object)
      attribute_str = ''
      unless an_object.nil?
        # Need to determine how to proceed based on the object type
        if an_object.is_a?(Hash)
          last_index = an_object.size - 1
          attribute_str.concat('[')
          an_object.each_with_index do |(k, v), index|
            attribute_str.concat('[')
            attribute_str.concat("'#{k}', #{attributes_to_wsadmin_str(v)}")
            attribute_str.concat(']')
            attribute_str.concat(', ') if index < last_index
          end
          attribute_str.concat(']')
        elsif an_object.is_a?(Array)
          last_index = an_object.size - 1
          attribute_str.concat('[')
          an_object.each_with_index do |v, index|
            attribute_str.concat(attributes_to_wsadmin_str(v))
            attribute_str.concat(', ') if index < last_index
          end
          attribute_str.concat(']')
        else
          # I'm just a simple value
          attribute_str.concat("'#{an_object}'")
        end
      end
      attribute_str
    end

    def check_admin_args(admin_user = nil, admin_pass = nil)
      return "-username #{admin_user} -password #{admin_pass}" if admin_user && admin_pass
      ''
    end
  end
end
