# Base Grape class
class API < Grape::API
  version :v1
  format :json

  helpers {}

  # mount Routes::Datacentre
  # mount Routes::Server
  # mount Routes::Template
  # mount Routes::User

  add_swagger_documentation
end
