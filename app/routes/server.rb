module Routes
  # /servers
  class Servers < Grape::API
    resource :servers do
      before do
        authenticate!
      end

      desc 'List all servers'
      get do
        Server.all
      end
    end
  end
end
