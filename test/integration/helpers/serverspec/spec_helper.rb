require 'serverspec'

set :backend, :exec

RSpec.configure do |c|
  c.before :all do
    c.path = '$PATH:/sbin:/usr/sbin:/usr/local/sbin:/bin'
  end
end
