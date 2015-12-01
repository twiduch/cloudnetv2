require 'spec_helper'

describe BuildChecker::Orchestrator do
  it 'should raise error if no Datacentre synchornized' do
    expect { subject }.to raise_error RuntimeError
  end

  it 'should create new object and call run' do
    orchestrator = double('Orchestrator')
    expect(BuildChecker::Orchestrator).to receive(:new).and_return(orchestrator)
    expect(orchestrator).to receive(:run)
    BuildChecker::Orchestrator.run
  end

  context 'with Datacentre synchronized' do
    before :example do
      VCR.use_cassette 'UpdateFederationResources/should_fetch_the_template_store' do
        UpdateFederationResources.run
      end
    end
    
    it 'should initialize properly' do
      expect(subject).to be
    end
    
    it 'should read last built time from DB' do
      System.set(:last_test_vm_build, '2015-10-03 10:30')
      expect(subject.last_built_time).to eq '2015-10-03 10:30'
    end
    
    it 'should wait specified time for next build check' do
      stub_const('BuildChecker::Orchestrator::CHECK_EVERY', 0.01)
      stub_const('BuildChecker::Orchestrator::BUILD_EVERY', 1.hour)
      start = Time.now
      System.set(:last_test_vm_build, start)
      Timecop.scale(3600 * 6)
      subject.time_for_vm_build?
      expect(Time.now).to be > start + 1.hour
      Timecop.return
    end
    
    it 'should build test vm' do
      expect(BuildChecker::Builder).to receive(:build_test_vm)
      allow(subject).to receive(:time_for_vm_build?).and_return(true)
      subject.test_vm
    end
    
    it 'should verify if test vm built' do
      expect(BuildChecker::Monitor).to receive(:check)
      expect { |b| subject.verify_test_vm('args', &b) }.to yield_with_args
    end
    
    it 'should send notification if vms not cleaned up' do
      expect(BuildChecker::Builder).to receive(:destroy_test_vms).and_return 1
      expect(BuildChecker::Notifier).to receive(:test_vm_left)
      subject.clean_up
    end
  end
end
