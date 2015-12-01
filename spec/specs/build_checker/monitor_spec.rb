require 'spec_helper'

describe BuildChecker::Monitor do
  let(:server) { Fabricate(:server) }
  subject { BuildChecker::Monitor.new(server) }
  
  it 'should create new object and call check' do
    monitor = double('Monitor')
    expect(BuildChecker::Monitor).to receive(:new).and_return(monitor)
    expect(monitor).to receive(:check)
    BuildChecker::Monitor.check(server)
  end
  
  it 'should handle success' do
    subject.instance_variable_set(:@vm_built, true)
    expect { |b| subject.success(&b) }.to yield_with_no_args
    subject.instance_variable_set(:@vm_built, false)
    expect { |b| subject.success(&b) }.not_to yield_control
  end
  
  it 'should handle failure' do
    subject.instance_variable_set(:@vm_built, false)
    expect { |b| subject.error(&b) }.to yield_with_no_args
    subject.instance_variable_set(:@vm_built, true)
    expect { |b| subject.error(&b) }.not_to yield_control
  end
  
  it 'should return false if onapp error' do
    monitor = BuildChecker::Monitor.new({error: 'connection error'})
    expect(monitor.check).to be_falsey
  end
  
  it 'should set success if server on' do
    subject.server.state = :on
    subject.check
    expect(subject).to be_built
  end
  
  context 'Time for built expired' do
    before :example do
      stub_const('BuildChecker::Monitor::CHECK_EVERY', 0.01)
      stub_const('BuildChecker::Monitor::MAX_TIME_FOR_BUILT', 1.minute)
    end
    
    it 'should set error if direct call gives error' do
      expect(OnappAPI).to receive(:admin).and_return({error: 'error'})
      Timecop.scale(3600)
      subject.check
      Timecop.return
      expect(subject).not_to be_built
    end
    
    it 'should set error if direct call unsuccessful' do
      expect(OnappAPI).to receive(:admin).and_raise('error')
      Timecop.scale(3600)
      subject.check
      Timecop.return
      expect(subject).not_to be_built
    end
    
    it 'should set error if direct call does not give booted=>true' do
      expect(OnappAPI).to receive(:admin).and_return({'virtual_machine'=>{'booted'=> false}})
      Timecop.scale(3600)
      subject.check
      Timecop.return
      expect(subject).not_to be_built
    end
    
    it 'should set success if direct call gives booted=>true' do
      expect(OnappAPI).to receive(:admin).and_return({'virtual_machine'=>{'booted'=> true}})
      Timecop.scale(3600)
      subject.check
      Timecop.return
      expect(subject).to be_built
    end
  end
end