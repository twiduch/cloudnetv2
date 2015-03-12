require_relative 'contrib/guard_procfile'

## Uncomment and set this to only include directories you want to watch
# directories %w(app lib config test spec features)

## Uncomment to clear the screen before every task
# clearing :on

guard :bundler do
  require 'guard/bundler'
  require 'guard/bundler/verify'
  helper = Guard::Bundler::Verify.new

  files = ['Gemfile']
  files += Dir['*.gemspec'] if files.any? { |f| helper.uses_gemspec?(f) }

  # Assume files are symlinked from somewhere
  files.each { |file| watch(helper.real_path(file)) }
end

guard 'procfile_api' do
  watch('Gemfile.lock')
  watch(%r{^(config|lib|app)/.*})
end

# guard 'procfile_transaction_daemon'

guard 'bundler' do
  watch('Gemfile')
end
