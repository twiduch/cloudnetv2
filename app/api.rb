# Base Grape class
class API < Grape::API
  version :v1, using: :accept_version_header
  format :json

  helpers do
    def authenticate!(level)
    end
  end

  mount Routes::Datacentres
  mount Routes::Servers
  mount Routes::Users

  add_swagger_documentation
end
