# Base Grape class
class API < Grape::API
  version :v1, using: :accept_version_header
  format :json

  logger Cloudnet.logger

  rescue_from RuntimeError do |e|
    # TODO: Manually send to Sentry
    Cloudnet.logger.error e
    error! 'Internal Server Error. This has been logged.'
  end

  rescue_from Mongoid::Errors::Validations do |e|
    Cloudnet.logger.info e
    error!({ error: e.document.errors }, 400)
  end

  helpers do
    def authenticate!(_level)
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
  mount Routes::Auth

  add_swagger_documentation
end
