require 'spec_helper'

describe Server do
  describe 'OnApp API interaction' do
    before :each do
      # Don't persist the user, just instantiate one so we get the attributes
      user_details = Fabricate.build(:user).attributes
      User.create_with_synced_onapp_user user_details
      @user = User.find_by user_details[:email]

      UpdateFederationResources.run
    end

    after :each do
      api = OnappAPI.admin_connection
      api.delete "users/#{@user.id}", body: { force: 1 }
    end

    it 'should create and destroy an onapp server along with a local cloud.net server', :vcr do
      @server = Server.new(user: @user).provision
      expect(@server.onapp_identifier).to be nil
      expect(@server.state).to be :building
      @server.reload
      expect(@server.onapp_identifier).to be_a String
      @server.deprovision
      expect(Server.count).to eq 0
    end
  end
end
