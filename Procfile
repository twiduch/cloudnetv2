api: bundle exec puma config.ru
transaction_daemon: bundle exec rake transactions_sync
frontend: ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => 8000, :DocumentRoot => "#{Dir.pwd}/public").start'
worker: bundle exec sidekiq -r ./config/boot.rb
admin: bundle exec puma admin/config.ru
