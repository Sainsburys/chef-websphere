require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.platform = 'centos'
  config.version = '6.8'
  config.log_level = :error
  # Prohibit using the should syntax
  config.expect_with :rspec do |spec|
    spec.syntax = :expect
  end
  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end

def stub_commands
  stub_command('which sudo').and_return('/usr/bin/sudo')
  # allow(File).to receive(:exist?).and_call_original
  # allow(File).to receive(:exist?).with('/opt/IBM/WebSphere/AppServer/profiles/AppProfile1/bin/setupCmdLine.sh').and_return(true)
end

at_exit { ChefSpec::Coverage.report! }
