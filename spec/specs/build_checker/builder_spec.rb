require 'spec_helper'

describe BuildChecker::Builder do
  it 'should set built time in a DB' do
    expect(System.get(:last_test_vm_build)).to eq ''
    BuildChecker::Builder.note_new_built
    expect(System.get(:last_test_vm_build)).to be_a(Time)
  end

  it 'should create new object and call build_test_vm' do
    builder = double('Builder')
    expect(BuildChecker::Builder).to receive(:new).and_return(builder)
    expect(builder).to receive(:build_test_vm)
    BuildChecker::Builder.build_test_vm
  end

  context 'Destroying VMs' do
    it 'should create new object and call destroy_test_vms' do
      builder = double('Builder')
      expect(BuildChecker::Builder).to receive(:new).and_return(builder)
      expect(builder).to receive(:destroy_test_vms)
      BuildChecker::Builder.destroy_test_vms
    end

    it 'should call API to delete test VM at OnApp' do
      vm = Fabricate :server, onapp_identifier: 'abc'
      expect(OnappAPI).to receive(:admin).with(:delete, 'virtual_machines/abc')
      subject.destroy_onapp_vm(vm)
    end

    it 'should handle error if API delete call unsuccessful' do
      vm = Fabricate :server, onapp_identifier: 'abc'
      expect(OnappAPI).to receive(:admin).and_raise('error msg')
      expect(subject.destroy_onapp_vm(vm)).to eq 'errors' => 'error msg'
    end

    context 'all test VMs' do
      before :example do
        datacentre = Fabricate(:datacentre)
        templ1 = Fabricate(:template, datacentre: datacentre)
        templ2 = Fabricate(:template, datacentre: datacentre)
        Fabricate(:server, user: nil, hostname: subject.class::HOSTNAME,
                           template: templ1, onapp_identifier: 's1')
        Fabricate(:server, user: nil, hostname: subject.class::HOSTNAME,
                           template: templ2, onapp_identifier: 's2')
        Fabricate(:transaction, identifier: 's1')
        Fabricate(:transaction, identifier: 's2')
      end

      it 'should destroy local test vms if onapp delete call was successful' do
        responses = [nil, 'errors' => ['VirtualMachine not found']]
        expect(subject).to receive(:destroy_onapp_vm).twice.and_return(*responses)
        expect do
          expect(subject.destroy_test_vms).to eq 0
        end.to change { Server.count }.from(2).to(0)
        expect(Transaction.count).to eq 0
      end

      it 'should return how many VMs were NOT destroyed' do
        expect(subject).to receive(:destroy_onapp_vm).twice.and_return(nil, error: 'err')
        expect do
          expect(subject.destroy_test_vms).to eq 1
        end.to change { Server.count }.from(2).to(1)
        expect(Server.first.transactions.count).to eq 1
      end
    end
  end

  context 'Building VMs' do
    it 'should find ubuntu template' do
      datacentre = Fabricate(:datacentre)
      Fabricate(:template, datacentre: datacentre)
      expect(subject.ubuntu_template).to eq nil
      Fabricate(:template, os_distro: 'ubuntu', datacentre: datacentre)
      template = subject.ubuntu_template
      expect(template).to be_a(Template)
      expect(subject.template).to eq template
    end

    it 'should find linux template' do
      datacentre = Fabricate(:datacentre)
      Fabricate(:template, os: 'windows', datacentre: datacentre)
      expect(subject.first_linux_template).to eq nil
      Fabricate(:template, datacentre: datacentre)
      template = subject.first_linux_template
      expect(template).to be_a(Template)
      expect(subject.template).to eq template
    end

    it 'should create local vm representation' do
      Fabricate(:template)
      server = subject.new_local_vm
      expect(server.name).to eq 'build checker test-0'
      expect(server.hostname).to eq subject.class::HOSTNAME
    end

    it 'should call API to create test VM at OnApp' do
      Fabricate(:template)
      params = subject.onapp_server_params
      expect(params[:body][:virtual_machine][:note]).to eq 'cloud.net test built'
      expect(OnappAPI).to receive(:admin).with(:post, 'virtual_machines', params)
      subject.new_onapp_vm
    end

    it 'should handle error if API create call unsuccessful' do
      Fabricate(:template)
      expect(OnappAPI).to receive(:admin).and_raise('error msg')
      expect(subject.new_onapp_vm).to eq 'errors' => 'error msg'
    end
  end

  it 'should return error if no linux templates' do
    Fabricate(:template, os: 'windows', os_distro: 'R2')
    expect(subject.build_test_vm).to eq ['No linux template available']
  end

  it 'should return error if API create VM was unsuccessful', :vcr do
    Fabricate(:template)
    expect(subject.build_test_vm).to be_a Hash
  end

  it 'should create VM if API create call was successful', :vcr do
    Fabricate(:template, id: 31)
    server = subject.build_test_vm
    expect(server).to be_a Server
    expect(server.onapp_identifier).to eq 'fivnj9fcpqkrdv'
    expect(server.user).to be nil
  end
end
