# Base Grape class
class API < Grape::API
  version :v1, using: :accept_version_header
  format :json

  logger Cloudnet.logger

  rescue_from RuntimeError do |e|
    # TODO: Manually send to Sentry
    Cloudnet.logger.error e
    error!({ message: { error: 'Internal Server Error. This has been logged.' } }, 500)
  end

  rescue_from Mongoid::Errors::Validations do |e|
    Cloudnet.logger.info e
    error!({ message: { error: e.document.errors } }, 400)
  end

  rescue_from Mongoid::Errors::DocumentNotFound do |e|
    Cloudnet.logger.info e
    error!({ message: { error: 'Resource not found' } }, 404)
  end

  rescue_from Grape::Exceptions::ValidationErrors do |e|
    Cloudnet.logger.info e
    error!({ message: { error: e } }, 400)
  end

  helpers do
    def current_user
      @current_user ||= User.authorize(headers['Authorization'])
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_user
    end
  end

  desc 'About the API'
  get '/' do
    {
      'Cloudnet API' => Cloudnet::VERSION,
      status: {
        worker: { processes: Sidekiq::ProcessSet.new.size },
        transactions_daemon: {
          time_since_last_sync: Cloudnet.time_since_last_transactions_sync
        }
      }
    }
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
