require 'rack/cors'
require_relative 'config/boot'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :any
  end
end

run API
