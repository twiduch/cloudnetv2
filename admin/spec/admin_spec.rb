require 'spec_helper'
include Warden::Test::Helpers

describe 'Admin', type: :request do
  let(:server) { Fabricate :server }
  let(:admin) { Fabricate :admin_user }

  it 'should set the modifier of History Tracker changes when making changes to records' do
    login_as admin, scope: :admin_user
    expect(server.suspended).to be true
    patch "/servers/#{server.id}", server: { suspended: false }
    server.reload
    expect(server.suspended).to be false
    change = HistoryTracker.find_by(scope: 'server', action: 'update')
    expect(change.modifier_tag).to eq 'admin-1'
    expect(change.modified).to eq 'suspended' => false
  end
end
