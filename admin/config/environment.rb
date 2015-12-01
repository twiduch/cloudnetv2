# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Manually load gems to avoid unnecessary load times for the Grape API
require 'devise'
require 'activeadmin'

# This needs to be called in order to provide the page() method to Mongoid models.
# I don't know why it isn't automaticalliy called. Maybe because of not loading all of rails
# in `application.rb`?
Kaminari::Hooks.init

# Cloud.net boot
require_relative '../../config/boot'

# Initialize the Rails application.
Rails.application.initialize!

if AdminUser.count == 0
  admin = AdminUser.create! email: 'admin@cloud.net', password: 'CHANGEME!'
  Cloudnet.logger.info "Admin user creeated: user: #{admin.email}, pass: #{admin.password}"
end
