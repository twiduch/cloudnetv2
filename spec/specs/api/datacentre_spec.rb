require 'spec_helper'

describe API do
  include Rack::Test::Methods

  def app
    API
  end

  let(:user) { Fabricate :user }

  describe 'Datacentre methods' do
    before :each do
      Sidekiq::Testing.fake!
      header 'Authorization', "APIKEY #{user.cloudnet_api_key}"
      Fabricate :template # Includes creation of datacentre
    end

    it 'should return all the datacentres' do
      get '/datacentres'
      response = JSON.parse(last_response.body)
      expect(response.count).to eq 1
      expect(response.first['label']).to eq Datacentre.first.label
      datacentre = response.first
      expect(datacentre['templates'].count).to eq 1
      expect(datacentre['templates'].first['label']).to eq Template.first.label
    end

    it 'should return info about a particular datacentre' do
      get "/datacentres/#{Datacentre.first.id}"
      response = JSON.parse(last_response.body)
      expect(response['label']).to eq Datacentre.first.label
      expect(response['templates'].count).to eq 1
      expect(response['templates'].first['label']).to eq Template.first.label
    end
  end
end
