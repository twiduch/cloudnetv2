web: bundle exec puma -t 5:5 -p ${PORT:-9292} -e ${RACK_ENV:-development}
transaction_daemon: bundle exec rake transactions_sync
frontend: ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => ENV["PORT"], :DocumentRoot => "#{Dir.pwd}/frontend/build").start'
api_docs: ruby -rwebrick -e'WEBrick::HTTPServer.new(:Port => ENV["PORT"], :DocumentRoot => "#{Dir.pwd}/frontend/docs").start'
worker: bundle exec sidekiq -r ./config/boot.rb
admin: bundle exec puma -p ${PORT:-9293} -e ${RACK_ENV:-development}
