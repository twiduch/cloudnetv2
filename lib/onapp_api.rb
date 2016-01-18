require 'faraday'

# Adds some syntactic sugar to models, so that you can interact with cloud.net's representation
# of the object on Onapp. Eg;
# `user = User.find 1`
# `u.onapp.api :get , {params: 123}`
module OnappAPI
  # Map basic CRUD methods
  class OnappAPIConnection
    # `object` An instance of a cloud.net model or :admin for an admin connection
    def initialize(object)
      fail StandardError, 'Use conn() for admin requests' unless object.respond_to? :onapp_identifier
      # Always create a user-specific connection to the Onapp API. This way we make use of Onapp's
      # user isolation. See: http://onapp.com/cloud/features/security/
      @object = object
      @onapp_resource_name = translate_resource_name(object.class.to_s)
    end

    # Make a resource-specific API request
    def api(method = :get, params = nil)
      if @object.onapp_identifier
        path = "#{@onapp_resource_name}/#{@object.onapp_identifier}"
      else
        path = @onapp_resource_name
      end
      OnappAPI.request(@object.user, method, path, params)
    end

    private

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

    # Just a means to make it clear that you're getting an *admin* connection
    def admin(method, path, params = nil)
      request(:admin, method, path, params)
    end

    def request(user, method, path, params)
      check_for_env_credentials
      path = "#{path}.json"
      connection = get_connection user
      response = make_request connection, method, path, params
      if response.body.empty?
        nil
      else
        JSON.parse response.body
      end
    end

    private

    def make_request(connection, method, path, params)
      Cloudnet.logger.debug "OnApp API request: #{method.upcase} #{path} #{params}"
      connection.send(method) do |request|
        request.url path
        add_params request, params if params
      end
    rescue Faraday::ClientError => exception
      raise exception, exception.response
    end

    def add_params(request, params)
      if params[:body]
        request.headers['Content-Type'] = 'application/json'
        request.body = JSON.generate params[:body]
      else
        request.params = params
      end
    end

    def get_connection(user)
      ssl_verify = Cloudnet.environment == 'production'
      Faraday.new(url: API_URI, ssl: { verify: ssl_verify }) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.basic_auth(*credentials(user))
      end
    end

    def credentials(user)
      if user.is_a? User
        username = user.onapp_username
        password = user.onapp_password
      elsif user == :admin
        username = API_USER
        password = API_PASS
      else
        fail 'Invalid user for OnApp API'
      end
      [username, password]
    end

    def check_for_env_credentials
      return if API_URI && API_USER && API_PASS
      fail 'Cannot find OnApp API credentials in ENV[]'
    end
  end

  # The magical method that allows things like `server.onapp.post(ram: 100000000000000)`
  def onapp
    OnappAPIConnection.new(self)
  end
end
