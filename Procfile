api-web: bundle exec puma -t 5:5 -p ${PORT:-9292} -e ${RACK_ENV:-development}
frontend-web: ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => ENV["PORT"], :DocumentRoot => "#{Dir.pwd}/frontend/build").start'
docs-web: ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => ENV["PORT"], :DocumentRoot => "#{Dir.pwd}/frontend/docs").start'
admin-web: bundle exec puma -p ${PORT:-9293} -e ${RACK_ENV:-development} admin/config.ru
transaction_daemon: bundle exec rake transactions_sync
worker: bundle exec sidekiq -r ./config/boot.rb
