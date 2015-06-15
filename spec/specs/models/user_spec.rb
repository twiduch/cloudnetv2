require 'spec_helper'

describe User do
  describe 'OnApp API interaction' do
    before do
      @user_details = Fabricate.build(:user).attributes
    end

    after do
      api = OnappAPI.admin_connection
      api.delete "users/#{@user.id}"
      # TODO: Run the exact same deletion request again, to *completely* delete the user.
      # Currently the OnApp will not honour the second deletion until all the transactions have
      # completed from the first deletion.
    end

    it 'should create an onapp user along with a local cloud.net user', :vcr do
      expect(@user_details).not_to have_key :id
      expect(@user_details).not_to have_key :onapp_api_key
      Sidekiq::Testing.inline! do
        expect(User.count).to eq 0
        User.create_with_synced_onapp_user @user_details
        expect(User.count).to eq 1
        @user = User.find_by @user_details[:email]
        expect(@user.id.class).to be Fixnum
        expect(@user.onapp_api_key.empty?).to be false
      end
    end
  end

  it 'should raise validation errors before sending user to worker for creation' do
    expect do
      User.create_with_synced_onapp_user email: nil
    end.to raise_error Mongoid::Errors::Validations
  end
end
