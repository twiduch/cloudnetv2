require 'rack/cors'
require_relative 'config/boot'

# Cross Origin requests
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :any
  end
end

use Rack::Static, urls: ['/assets'], root: 'frontend/build'

module Rack
  # Route to a rackup depending on subdomain
  class Subdomain
    def initialize(routes = [])
      @routes = routes
      yield self if block_given?
    end

    def map(subdomain)
      @routes << { subdomain: subdomain, application: yield }
    end

    def call(env)
      @routes.each do |route|
        match = env['HTTP_HOST'].match(route[:subdomain])
        return route[:application].call(env) if match
      end
      API.call(env)
    end
  end
end

app = Rack::Subdomain.new do |domain|
  domain.map 'www' do
    lambda do |_env|
      [
        200,
        {
          'Content-Type'  => 'text/html',
          'Cache-Control' => 'public, max-age=86400'
        },
        File.open('frontend/build/index.html', File::RDONLY)
      ]
    end
  end

  domain.map 'api' do
    API
  end
end

run app
