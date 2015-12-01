require 'spec_helper'

describe Email do
  context 'test_vm_left' do
    it 'should send an email' do
      Email.test_vm_left.deliver!
      expect(Mail::TestMailer.deliveries.length).to eq 1
    end

    it 'should create and populate HTML ERB templates' do
      Email.test_vm_left.deliver!
      email = Mail::TestMailer.deliveries.first
      expect(email.body.parts.first.body).to match(/succesfully built, but I was not able to remove it/)
    end
  end

  context 'test_vm_not_built' do
    it 'should send an email' do
      Email.test_vm_not_built.deliver!
      expect(Mail::TestMailer.deliveries.length).to eq 1
    end

    it 'should create and populate HTML ERB templates' do
      Email.test_vm_not_built.deliver!
      email = Mail::TestMailer.deliveries.first
      expect(email.body.parts.first.body).to match(/not able to create Test VM in OnappCP/)
    end
  end
end
