ENV['RAILS_ENV'] = ENV['RACK_ENV'] = 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require '../spec/spec_helper'
