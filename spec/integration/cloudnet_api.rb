# Make API requests to the cloud.net API as if we were an end-user
module CloudnetAPI
  private

  def cloudnet_api_connection
    host = Capybara.app_host.gsub('www', 'api')
    port = Capybara.current_session.server.port
    Faraday.new(url: "#{host}:#{port}", ssl: { verify: false }) do |faraday|
      faraday.use Faraday::Response::RaiseError
      faraday.adapter Faraday.default_adapter
    end
  end

  def cloudnet_api_request(verb, path, params = nil)
    begin
      response = make_faraday_request verb, path, params
    rescue Faraday::ClientError => exception
      raise exception, exception.response
    end
    JSON.parse response.body
  end

  def make_faraday_request(verb, path, params = nil)
    cloudnet_api_connection.send(verb) do |request|
      request.headers['Authorization'] = "APIKEY #{@api_key}"
      request.url path
      request.params = params if params
    end
  end
end
