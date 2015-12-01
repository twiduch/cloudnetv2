require 'spec_helper'

describe BuildChecker::Notifier do
  let(:subject) { BuildChecker::Notifier }
  let(:mailer) { double('Email', deliver: true) }

  context '#test_vm_not_built' do
    it 'should send Email if VM not built' do
      expect(Email).to receive(:test_vm_not_built).and_return(mailer)
      subject.test_vm_not_built
    end
    
    it 'should handle errors when sending emails' do
      expect(Email).to receive(:test_vm_not_built).and_return raise_error
      expect(subject).to receive(:logger).twice.and_return(double(info: true))
      expect {subject.test_vm_not_built}.not_to raise_error
    end
  end
  
  context '#test_vm_left' do
    it 'should send Email if VM not destroyed' do
      expect(Email).to receive(:test_vm_left).and_return(mailer)
      subject.test_vm_left
    end
  
    it 'should handle errors when sending emails' do
      expect(Email).to receive(:test_vm_left).and_return raise_error
      expect(subject).to receive(:logger).twice.and_return(double(info: true))
      expect {subject.test_vm_left}.not_to raise_error
    end
  end
end