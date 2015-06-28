module Routes
  # /users
  class Auth < Grape::API
    resource :auth do
      desc 'Register a new user'
      params do
        requires :full_name, allow_blank: false
        requires :email, regexp: /.+@.+/, allow_blank: false
      end
      post :register do
        User.create_with_synced_onapp_user(
          full_name: params[:full_name],
          email: params[:email]
        )
        { message: 'Thank you for registering. You will be emailed shortly.' }
      end

      desc 'Confirm a user with the token received through registration'
      params do
        requires :token, allow_blank: false
        requires(
          :password,
          regexp: /^.{8,}$$/,
          desc: 'Password must be 8 or more characters'
        )
      end
      put :confirm do
        if User.confirm_from_token params[:token], params[:password]
          { message: 'You are now confirmed. Acces your key from `auth/api_key`' }
        else
          error! 'Confirmation failed', 400
        end
      end

      desc 'Get a short-lived login token for use with the HTML frontend'
      params do
        requires :email, regexp: /.+@.+/, allow_blank: false
        requires :password, allow_blank: false
      end
      get :token do
        user = User.find_by email: params[:email]
        return error!('User is not active', 403) unless user.status == :active
        return error!('Invalid password', 403) unless user.password == params[:password]
        {
          token: user.generate_new_login_token,
          user: user
        }
      end

      desc 'Verify an existing user based on their token or API key'
      get :verify do
        authenticate!
        { user: current_user }
      end
    end
  end
end
