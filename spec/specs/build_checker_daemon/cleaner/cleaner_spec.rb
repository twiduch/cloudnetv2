require 'spec_helper'

describe BuildChecker::Cleaner::Cleaner do
  let(:server) { Fabricate :server }
  subject { BuildChecker::Cleaner::Cleaner.new(server) }

  it 'creates new object and call destroy_test_vm' do
    cleaner = double('Cleaner')
    expect(BuildChecker::Cleaner::Cleaner).to receive(:new).and_return(cleaner)
    expect(cleaner).to receive(:destroy_test_vm)
    BuildChecker::Cleaner::Cleaner.destroy_test_vm(server)
  end

  it 'returns error message if API destroy VM call was unsuccessful', :vcr do
    expect(subject.destroy_onapp_vm).to be_a(Hash)
  end

  it 'returns nil if API destroy call was successful', :vcr do
    expect(subject.destroy_onapp_vm).to be_nil
  end

  it 'handles error if API delete call unsuccessful' do
    expect(OnappAPI).to receive(:admin).and_raise('error message')
    expect(subject.destroy_onapp_vm).to eq 'errors' => 'error message'
  end

  it 'removes local server when API call succesful' do
    expect(OnappAPI).to receive(:admin).with(:delete, "virtual_machines/#{server.onapp_identifier}")
    expect(subject.destroy_test_vm).to eq server
    expect(Server.count).to eq 0
    expect(Server.deleted.count).to eq 0
  end

  it 'removes local server when Onapp VM does not exist' do
    expect(OnappAPI).to receive(:admin).with(:delete, "virtual_machines/#{server.onapp_identifier}")
      .and_return 'errors' => ['VirtualMachine not found']
    expect(subject.destroy_test_vm).to eq server
    expect(Server.count).to eq 0
    expect(Server.deleted.count).to eq 0
  end

  it 'returns error if API call unsuccesful' do
    expect(OnappAPI).to receive(:admin).with(:delete, "virtual_machines/#{server.onapp_identifier}")
      .and_return 'errors' => 'error message'
    expect(subject.destroy_test_vm).to eq 'errors' => 'error message'
    expect(Server.count).to eq 1
  end

  it 'removes all data about server' do
    3.times { Fabricate :transaction, identifier: server.onapp_identifier }
    server.update_attribute(:state, :on)
    server.update_attribute(:memory, 1024)

    expect(server.history_tracks.count).to eq 3
    expect(server.transactions.count).to eq 3
    expect(Server.count). to eq 1
    subject.remove_local_data
    expect(server.history_tracks.count).to eq 0
    expect(server.transactions.count).to eq 0
    expect(Server.count). to eq 0
    expect(Server.deleted.count).to eq 0
  end
end
