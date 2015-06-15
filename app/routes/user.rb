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

      desc 'Register a new user'
      params do
        requires :full_name, type: String, allow_blank: false
        requires :email, regexp: /.+@.+/, allow_blank: false
      end
      post :register do
        User.create_with_synced_onapp_user(
          full_name: params[:full_name],
          email: params[:email]
        )
        'Thank you for registering. You will be emailed shortly.'
      end
    end
  end
end
