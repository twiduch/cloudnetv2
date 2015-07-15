require 'httparty'
require 'blanket'

# Adds some syntactic sugar to models, so that you can interact with cloud.net's representation
# of the object on Onapp. Eg;
# `user = User.find 1`
# `u.onapp.show`
# Will query the Onapp API for the user whose cloud.net ID is 1 (even though their Onapp ID will
# be different)
module OnappAPI
  # Map basic CRUD methods
  class OnappAPIConnection
    # `object` An instance of a cloud.net model
    def initialize(object)
      # Always create a user-specific connection to the Onapp API. This way we make use of Onapp's
      # user isolation. See: http://onapp.com/cloud/features/security/
      @object = object
      @onapp_resource_name = translate_resource_name(@object.class)
      @api = OnappAPI.connection(user)
      endpoint
    end

    private

    # Represents the API call's base URL. Eg; `https://api.onapp.com/user/123`
    def endpoint
      if new_record?
        @api.send(@onapp_resource_name)
      else
        @api.send(@onapp_resource_name, @object.onapp_identifier)
      end
    end

    def translate_resource_name(name)
      {
        'Server' => 'virtual_machines',
        'User' => 'users'
      }[name]
    end
  end

  class << self
    API_URI = ENV['ONAPP_URI']
    API_USER = ENV['ONAPP_USER']
    API_PASS = ENV['ONAPP_PASS']

    # General purpose connection to the Onapp API using the Blanket gem.
    # See: https://github.com/inf0rmer/blanket
    # Eg;
    # `github = Blanket.wrap("https://api.github.com")`
    # Get some user's info...
    # `user = github.users('inf0rmer').get`
    def connection(user)
      check_for_env_credentials
      disable_ssl_verification_in_non_production
      Blanket.wrap(
        API_URI,
        extension: :json, # Always appends '.json' to the end of the request URL
        headers: {
          'Authorization' => "Basic #{auth_sig(user)}"
        }
      )
    end

    # Create the base64 encoded string for the Basic Auth header
    def auth_sig(user)
      if user.is_a? User
        username = user.email
        password = user.password
      elsif user == :admin
        username = API_USER
        password = API_PASS
      end
      Base64.encode64("#{username}:#{password}").delete("\r\n")
    end

    # Just a means to make it clear that you're getting and *admin* connection
    def admin_connection
      connection(:admin)
    end

    def check_for_env_credentials
      return if API_URI && API_USER && API_PASS
      fail 'Cannot find OnApp API credentials in ENV[]'
    end

    def disable_ssl_verification_in_non_production
      return if Cloudnet.environment == 'production'
      HTTParty::Basement.default_options.update(verify: false)
    end
  end

  # The magical method that allows things like `server.onapp.post(ram: 100000000000000)`
  def onapp
    OnappAPIConnection.new self
  end
end
