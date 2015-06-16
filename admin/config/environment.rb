# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Requiring these are disabled in the Gemfile, because the Gemfile is primarily for the
# Grape API.
require 'devise'
require 'activeadmin'

# This needs to be called in otrder to provide the page() method to Mongoid models.
# I don't know why it isn't automaticalliy called. Maybe because of not loading all of rails
# in `application.rb`?
Kaminari::Hooks.init

# Cloud.net boot
require_relative '../../config/settings'
Cloudnet.init

# Initialize the Rails application.
Rails.application.initialize!
