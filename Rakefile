require 'rubygems'
require 'bundler'
require 'rake'

ENV['RACK_ENV'] ||= 'development'

task :boot do
  require File.expand_path('../config/boot', __FILE__)
end

namespace :assets do
  desc 'Create the frontend HTML, CSS, JS and images'
  task :precompile do |_t, _args|
    # Compile admin assets
    system 'export ASSET_COMPILATION=true; export PATH=/tmp/build/bin:$PATH; cd admin; rake assets:precompile 2>&1'
    # Compile frontend assets
    system 'cd frontend && ../node_modules/.bin/gulp production'
  end

  desc 'Noop'
  task :clean do |_t, _args|
  end
end

desc 'Grape API Routes'
task routes: :boot do
  mapped_prefix = ''
  params_str = ' params:'
  desc_limit = 25
  route_info = API.routes.map { |r| [r, r.instance_variable_get(:@options)] }
  max_desc_size     = route_info.map { |_, info| (info[:description] || '')[0..desc_limit].size }.max
  max_method_size   = route_info.map { |_, info| info[:method].size }.max
  max_version_size  = route_info.map { |_, info| info[:version].size }.max
  max_path_size     = route_info.map { |_, info| info[:path].sub(':version', info[:version]).size }.max
  max_params_digits = route_info.map { |_, info| info[:params].size.to_s.size }.max
  format_str = format(
    '%%%ds  %%%ds %%%ds %%%ds%%-%ds | %%%ds%%%ds  %%s',
    max_desc_size + 1,
    max_version_size,
    max_method_size,
    mapped_prefix.size,
    max_path_size,
    max_params_digits,
    params_str.size)

  route_info.each do |_, info|
    fields = [
      info[:description] ? info[:description][0..desc_limit] : '',
      info[:version],
      info[:method],
      mapped_prefix,
      info[:path].sub(':version', info[:version]),
      info[:params].size.to_s,
      params_str,
      info[:params].first.inspect
    ]
    puts format(format_str, *fields)

    info[:params].drop(1).each do |param|
      puts format(format_str, *([''] * (fields.size - 1)) + [param.inspect])
    end
  end
end

desc 'Run pry console'
task console: :boot do |_t, _args|
  require 'pry'

  def reload!
    ENV['SKIP_ONAPP_API_CHECK'] = 'true'
    Cloudnet.require_app use_load: true
  end

  ARGV.clear
  Pry.start
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
