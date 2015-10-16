api: bundle exec puma config.ru
transaction_daemon: bundle exec rake transactions_sync
frontend: ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => ENV["PORT"], :DocumentRoot => "#{Dir.pwd}/frontend/build").start'
api_docs: ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => ENV["PORT"], :DocumentRoot => "#{Dir.pwd}/frontend/docs").start'
worker: bundle exec sidekiq -r ./config/boot.rb
admin: bundle exec puma admin/config.ru
