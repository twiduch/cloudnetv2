require 'spec_helper'

describe HistoryTracker do
  let(:server) { Fabricate :server }

  it 'should track changes to a record' do
    expect(HistoryTracker.count).to eq 0
    server.update_attributes!(state: :built)
    archive = HistoryTracker.find_by(scope: 'server', action: 'update')
    expect(archive.modified).to eq 'state' => :built
    expect(archive.scope_id).to eq server.id.to_s
    expect(archive.scope_owned_by_id).to eq server.user.id
    expect(archive.modifier).to eq nil
    expect(archive.modifier_tag).to eq :ruby
  end
end
