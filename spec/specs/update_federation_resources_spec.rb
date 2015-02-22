require 'spec_helper'

describe UpdateFederationResources, :vcr do
  it 'should fetch the template store' do
    subject.run
  end
end
