require 'spec_helper'

describe UpdateFederationResources, :vcr do
  it 'should fetch the template store' do
    expect { subject.run }.to change { Template.count }
  end
end
