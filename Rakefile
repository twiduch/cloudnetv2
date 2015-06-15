require 'rubygems'
require 'bundler'

ENV['RACK_ENV'] ||= 'development'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rake'

task :boot do
  require File.expand_path('../config/boot', __FILE__)
end

desc 'Run pry console'
task :console do |_t, _args|
  exec 'pry -r ./config/boot'
end

desc 'Sync Onapp transactions to our DB'
task transactions_sync: :boot do
  Transactions::Sync.run
end

desc "Migrate Jager's SQL DB to our DB"
task migrate_from_jager: :boot do
  MigrateFromJager.run
end

desc 'Query the Federation for the latest available datacentres and templates'
task update_federation_resources: :boot do
  UpdateFederationResources.run
end

desc 'Create the non-privelged OnApp user role that all cloud.net users use to interact with OnApp'
task create_onapp_role: :boot do
  role_id = User.create_onapp_role
  puts "Role created. ID is #{role_id}, set this value to the ONAPP_ROLE key in .env"
end

desc 'Show the role IDs of the current OnApp user role'
task show_onapp_role: :boot do
  response = OnappAPI.admin_connection.get "roles/#{Cloudnet.onapp_cloudnet_role}"
  list = response.role.permissions.map do |perm|
    "#{perm['permission']['id']}: " \
    "(#{perm['permission']['identifier'].upcase}) '#{perm['permission']['label']}'"
  end
  puts list.join("\n")
end
