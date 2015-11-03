require 'spec_helper'

describe API do
  include Rack::Test::Methods

  def app
    API
  end

  let(:server) { Fabricate :server }

  describe 'Server methods' do
    before :each do
      Sidekiq::Testing.fake!
      header 'Authorization', "APIKEY #{server.user.cloudnet_api_key}"
      Fabricate :transaction
    end

    it "should return the user's servers" do
      get '/servers'
      response = JSON.parse(last_response.body)
      expect(response.first['hostname']).to eq server.hostname
      expect(response.first['transactions'][0]['details']).to eq 'building'
    end

    it 'should create a server' do
      post '/servers', template: Template.first.id
      response = JSON.parse(last_response.body)
      expect(response['name']).to eq "Rspec Test User's Server 2"
      expect(response['cpus']).to eq 1
      expect(response['memory']).to eq 512
      job = ModelWorkerSugar::ModelWorker.jobs.first
      expect(job['args']).to eq [
        'Server', response['id'], 'create_onapp_server'
      ]
    end

    it 'should delete a server' do
      server_id = server.id.to_s
      delete "/servers/#{server_id}"
      response = JSON.parse(last_response.body)
      expect(response['message']).to eq "Server #{server_id} has been scheduled for destruction"
      job = ModelWorkerSugar::ModelWorker.jobs.first
      expect(job['args']).to eq [
        'Server', server_id, 'destroy_onapp_server'
      ]
    end
  end
end
