require 'rack/cors'
require_relative 'config/boot'

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
