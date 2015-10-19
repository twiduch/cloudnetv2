require 'spec_helper'
require 'webmock/rspec'

describe OnappAPI do
  before do
    VCR.turn_off!
    # Annoying that VCR.turn_off! doesn't turn off this request from the config...
    stub_request(
      :get, /version.json/
    ).to_return(status: 200, body: '{"version": "' + Cloudnet::ONAPP_API_VERSION + '"}')
    @host = URI.parse(ENV['ONAPP_URI']).hostname
  end

  after do
    VCR.turn_on!
  end

  it 'should make a user-based request when called from a resource instance' do
    server = Fabricate :server
    stub_request(:post, /virtual_machines/)
    server.onapp.post
    regex = Regexp.new(
      "https://#{CGI.escape(server.user.onapp_username)}:.*@#{@host}/virtual_machines.json"
    )
    expect(
      a_request(:post, regex)
    ).to have_been_made
  end

  it 'should make an admin request' do
    stub_request(:post, /users/)
    api = OnappAPI.admin_connection
    api.users.post
    regex = Regexp.new(
      "https://#{ENV['ONAPP_USER']}:.*@#{@host}/users.json"
    )
    expect(
      a_request(:post, regex)
    ).to have_been_made
  end
end
