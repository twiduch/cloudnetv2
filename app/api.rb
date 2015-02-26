# Base Grape class
class API < Grape::API
  version :v1, using: :accept_version_header
  format :json

  helpers do
    def authenticate!(level)
    end
  end

  desc 'About the API'
  get '/' do
    { 'Cloudnet API' => Cloudnet::VERSION }
  end

  desc 'API version'
  get '/version' do
    { 'version' => Cloudnet::VERSION }
  end

  mount Routes::Datacentres
  mount Routes::Servers
  mount Routes::Users

  add_swagger_documentation
end
