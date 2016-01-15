require_relative 'config/boot' unless ENV['RACK_ENV'] == 'test'

require 'rack/cors'

use Rack::CommonLogger, Cloudnet.logger
use Raven::Rack

if ENV['RACK_ENV'] == 'development'
  puts 'Loading NewRelic in developer mode ...'
  require 'new_relic/rack/developer_mode'
  use NewRelic::Rack::DeveloperMode
end
NewRelic::Agent.manual_start

# Cross Origin requests
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :any
  end
end

map "http://api.#{ENV['CLOUDNET_DOMAIN']}/" do
  run API
end

map "http://www.#{ENV['CLOUDNET_DOMAIN']}/" do
  use Rack::Static, urls: ['/assets'], root: 'frontend/build'
  run lambda { |_env|
    [
      200,
      {
        'Content-Type'  => 'text/html',
        'Cache-Control' => 'public, max-age=86400'
      },
      File.open('frontend/build/index.html', File::RDONLY)
    ]
  }
end

map "http://docs.#{ENV['CLOUDNET_DOMAIN']}/" do
  use Rack::Static, urls: ['/dist'], root: 'frontend/docs'
  run lambda { |_env|
    [
      200,
      {
        'Content-Type'  => 'text/html',
        'Cache-Control' => 'public, max-age=86400'
      },
      File.open('frontend/docs/index.html', File::RDONLY)
    ]
  }
end
