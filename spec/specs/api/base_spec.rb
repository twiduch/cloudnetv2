require 'spec_helper'

describe API do
  include Rack::Test::Methods

  def app
    API
  end

  describe 'Root methods' do
    it 'should return the current version' do
      get '/version'
      response = JSON.parse(last_response.body)
      expect(response['version']).to eq Cloudnet::VERSION
    end

    it 'should return general info about the API' do
      Timecop.freeze(Time.now) do
        System.set(:transactions_last_sync_attempt, Time.now - 10)
        get '/'
        response = JSON.parse(last_response.body)
        expect(
          response['status']['worker']['processes']
        ).to eq Sidekiq::ProcessSet.new.size
        expect(
          response['status']['transactions_daemon']['time_since_last_sync']
        ).to eq 10
      end
    end
  end
end
