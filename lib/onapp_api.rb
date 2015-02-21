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
    def intialize(object)
      # Always create a user-specific connection to the Onapp API. This way we make use of Onapp's
      # user isolation. See: http://onapp.com/cloud/features/security/
      @object = object
      @onapp_resource_name = translate_resource_name(@object.class)
      @api = OnappAPI.connection(@object.user)
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
    # General purpose connection to the Onapp API using the Blanket gem.
    # See: https://github.com/inf0rmer/blanket
    # Eg;
    # `github = Blanket.wrap("https://api.github.com")`
    # Get some user's info...
    # `user = github.users('inf0rmer').get`
    def connection(user)
      if user.is_a? User
        username = user.email
        password = user.password
      elsif user == :admin
        username = ENV['ONAPP_USER']
        password = ENV['ONAPP_PASS']
      end
      auth = Base64.encode64("#{username}:#{password}").delete("\r\n")
      Blanket.wrap(
        ENV['ONAPP_URI'],
        extension: :json, # Always appends '.json' to the end of the request URL
        headers: {
          'Authorization' => "Basic #{auth}"
        }
      )
    end

    # Just a means to make it clear that you're getting and *admin* connection
    def admin_connection
      connection(:admin)
    end
  end

  def onapp
    OnappAPIConnection.new self
  end
end
