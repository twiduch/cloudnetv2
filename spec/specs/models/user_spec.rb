require 'spec_helper'

describe User do
  let(:user) { Fabricate :user }

  describe 'OnApp API interaction' do
    before do
      # Don't persist the user, just instantiate one
      @user_details = Fabricate.build(:user).attributes
    end

    after do
      OnappAPI.admin :delete, "users/#{@user.id}", body: { force: 1 }
    end

    it 'should create an onapp user along with a local cloud.net user', :vcr do
      expect(@user_details).not_to have_key :id
      expect(User.count).to eq 0
      User.create_with_synced_onapp_user @user_details
      expect(User.count).to eq 1
      @user = User.find_by @user_details[:email]
      expect(@user.id.class).to be Fixnum
      expect(@user.onapp_username.empty?).to be false
      expect(@user.encrypted_onapp_password.empty?).to be false
      expect(@user.status).to be :pending
      expect(@user.encrypted_confirmation_token.empty?).to be false
      expect(Mail::TestMailer.deliveries.length).to eq 1
    end
  end

  it 'should raise validation errors before sending user to worker for creation' do
    expect do
      User.create_with_synced_onapp_user email: nil
    end.to raise_error Mongoid::Errors::Validations
  end

  describe 'Confirmation' do
    it 'should generate a confirmation token that can activate their account' do
      user.generate_token_for :confirmation_token
      confirmed = User.confirm_from_token user.confirmation_token, 'abcd1234'
      user.reload
      expect(confirmed).not_to be false
      expect(user.status).to be :active
    end

    it 'should not confirm an account with an invalid confirmation token' do
      confirmed = User.confirm_from_token 'invalid t0k3n', 'abcd1234'
      user.reload
      expect(confirmed).to be false
      expect(user.status).to be :pending
    end

    it 'should include the confirmation token in the welcome email' do
      user.generate_token_for :confirmation_token
      Email.welcome(user).deliver!
      email = Mail::TestMailer.deliveries.first
      expect(email.body.parts.first.body).to match(/#{user.confirmation_token}/)
    end
  end
end
