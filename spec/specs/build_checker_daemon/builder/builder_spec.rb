require 'spec_helper'

describe BuildChecker::Builder::Builder do
  let(:template) { Fabricate :template }
  subject { BuildChecker::Builder::Builder.new(template) }

  it 'creates new object and call build_test_vm' do
    builder = double('Builder')
    expect(BuildChecker::Builder::Builder).to receive(:new).and_return(builder)
    expect(builder).to receive(:build_test_vm)
    BuildChecker::Builder::Builder.build_test_vm(template)
  end

  it 'returns error if no template' do
    object = BuildChecker::Builder::Builder.new(nil)
    expect(object.build_test_vm).to eq ['No template']
  end

  it 'returns error message if API create VM was unsuccessful', :vcr do
    expect(subject.build_test_vm).to be_a Hash
  end

  it 'creates VM if API create call was successful', :vcr do
    server = subject.build_test_vm
    expect(server).to be_a Server
    expect(server.onapp_identifier).to eq 'jydn7c3fl4reli'
    expect(server.user).to be_nil
  end

  it 'creates local vm representation' do
    server = subject.new_local_vm
    expect(server.name).to eq "test template_id #{template.id}"
    expect(server.hostname).to eq BuildChecker::Builder::HOSTNAME
    expect(server.user).to be_nil
  end

  it 'calls API to create test VM at OnApp' do
    params = subject.onapp_server_params
    expect(params[:body][:virtual_machine][:note]).to eq 'cloud.net test built'
    expect(OnappAPI).to receive(:admin).with(:post, 'virtual_machines', params)
    subject.new_onapp_vm
  end

  it 'handles error if API create call unsuccessful' do
    expect(OnappAPI).to receive(:admin).and_raise('error msg')
    expect(subject.new_onapp_vm).to eq 'errors' => 'error msg'
  end
end
