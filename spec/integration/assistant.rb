require 'net/ssh'
require 'integration/cloudnet_api'

# Just a way to organise all the steps involved in running integration tests
module IntegrationAssistant
  include CloudnetAPI

  def setup
    @email = 'user@example.com'
  end

  def register
    visit '/auth/register'
    find(:css, '.fullname-input').set 'Mr. Person'
    find(:css, '.email-input').set @email
    find(:css, 'input[type=submit]').click
    expect(page).to have_css('.form-feedback')
    expect(find(:css, '.form-feedback')).to have_content('Thanks')
  end

  def goto_confirmation_page
    email = Mail::TestMailer.deliveries.first
    confirmation_link = email.body.parts.first.body.match(/href=[\'"]?([^\'" >]+)/)[0].gsub('href="', '')
    visit confirmation_link
  end

  def confirm
    goto_confirmation_page
    find(:css, '.password-input').set 'password'
    find(:css, '.passwordconfirm-input').set 'password'
    find(:css, 'input[type=submit]').click
    expect(page).to have_css('.form-feedback')
    expect(find(:css, '.form-feedback')).to have_content('Your account has been confirmed')
  end

  def login
    visit '/auth/login'
    find(:css, '.email-input').set @email
    find(:css, '.password-input').set 'password'
    find(:css, 'input[type=submit]').click
    expect(page).to have_content('Your Dashboard')
  end

  def note_api_key
    @api_key = find(:css, '.keyvalues-api-key-value').text
    @user = User.find_by email: @email
    expect(@api_key).to eq @user.cloudnet_api_key
  end

  def create_server
    expect do
      params = { template: Template.find_an_ubuntu_template.id }
      json = cloudnet_api_request(:post, '/servers', params)
      @server = Server.find json['id']
    end.to change { Server.count }.from(0).to(1)
  end

  def wait_for_server_to_boot
    Timeout.timeout(Cloudnet::SERVER_BUILD_MAX_WAIT) do
      loop do
        @server.reload
        break if @server.state == :on
        sleep 1
      end
      # Then add a few more seconds grace
      sleep 10
    end
  end

  def request_server_credentials
    json = cloudnet_api_request :get, "/servers/#{@server.id}"
    expect(json['ip_address']).not_to be_empty
    expect(json['initial_root_password']).not_to be_empty
  end

  def ssh_into_server
    hostname = Net::SSH.start(*ssh_args) do |ssh|
      ssh.exec!('hostname')
    end.strip
    expect(hostname).to eq @server.hostname
  end

  def ssh_args
    [
      @server.ip_address.strip,
      'root',
      {
        password: @server.initial_root_password,
        # Don't raise an error when there's a fingerprint mismatch
        paranoid: Net::SSH::Verifiers::Null.new
      }
    ]
  end

  def delete_server
    cloudnet_api_request :delete, "/servers/#{@server.id}"
    expect do
      cloudnet_api_request :get, "/servers/#{@server.id}"
    end.to raise_error Faraday::Error::ResourceNotFound
  end

  def cleanup
    # Cleanup the OnApp server because it won't get deleted if the integration tests fail half way through
    Server.all.each(&:destroy_onapp_server)
    # Cleanup the onapp user from the OnApp sandbox
    OnappAPI.admin(:delete, "users/#{@user.id}", body: { force: 1 }) if @user
  end
end
