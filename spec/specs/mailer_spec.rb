require 'spec_helper'

describe Email do
  let(:user) { User.new email: 'rspec@example.com', full_name: 'Testing' }

  it 'should send an email' do
    Email.welcome(user).deliver!
    expect(Mail::TestMailer.deliveries.length).to eq 1
  end

  it 'should create and populate HTML ERB templates' do
    Email.welcome(user).deliver!
    email = Mail::TestMailer.deliveries.first
    expect(email.body.raw_source).to match(/Hello #{user.full_name}/)
  end
end
