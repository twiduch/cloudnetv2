module Routes
  # /users
  class Users < Grape::API
    resource :users do
      before do
        authenticate! :admin
      end

      desc 'List all users'
      get do
        User.all
      end
    end
  end
end
