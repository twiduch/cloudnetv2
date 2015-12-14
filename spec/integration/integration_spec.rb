require 'integration/integration_helper'
require 'integration/assistant'

describe 'Registration' do
  include IntegrationAssistant

  before do
    setup
  end

  after do
    cleanup
  end

  # TODO: What about using proper it{} syntax for each stage? It would be possible if all the specs were ran in order
  # and the DB wasn't cleaned in the before{} block.
  it 'should allow a user to register, create a server, ssh into it and then destroy it' do
    register
    confirm
    login
    note_api_key
    create_server
    wait_for_server_to_boot
    request_server_credentials
    ssh_into_server
    delete_server
  end
end
