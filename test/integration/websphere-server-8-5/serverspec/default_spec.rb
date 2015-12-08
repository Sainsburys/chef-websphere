require_relative '../../../kitchen/data/spec_helper'

describe user('ibm') do
  it { should exist }
  it { belong_to_group 'x' }
end

describe group('x') do
  it { should exist }
end

describe file('/opt/oracle/Middleware/websphere-8.5/wlpserver') do
  it { should be_directory }
  it { should be_owned_by 'ibm' }
  it { should be_grouped_into 'x' }
end
