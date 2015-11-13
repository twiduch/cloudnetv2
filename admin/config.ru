# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

# Manually point to the unconvential compiled assets path in non-dev envs
use Rack::Static, urls: ['/assets'], root: 'admin/public' unless ENV['RACK_ENV'] == 'development'
run Rails.application
