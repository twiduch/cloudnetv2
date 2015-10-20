require 'spec_helper'

describe Server do
  describe 'OnApp API interaction' do
    before do
      # Don't persist the user, just instantiate one so we get the attributes
      user_details = Fabricate.build(:user).attributes
      User.create_with_synced_onapp_user user_details
      @user = User.find_by user_details[:email]

      UpdateFederationResources.run
    end

    after do
      api = OnappAPI.admin_connection
      api.delete "users/#{@user.id}", body: { force: 1 }
      @server.onapp.delete
    end

    it 'should create an onapp server along with a local cloud.net server', :vcr do
      @server = Server.new(user: @user).provision
      expect(@server.onapp_identifier).to be nil
      expect(@server.state).to be :building
      @server.reload
      expect(@server.onapp_identifier).to be_a String
    end
  end
end
