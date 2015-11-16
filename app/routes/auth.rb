module Routes
  # /users
  class Auth < Grape::API
    resource :auth do
      desc 'Register a new user', hidden: true
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

      desc 'Confirm a user with the token received through registration', hidden: true
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
          { message: 'You are now confirmed. Access your key from your dashboard' }
        else
          error! 'Confirmation failed', 400
        end
      end

      desc(
        'Get a short-lived login token for use with the HTML frontend',
        hidden: true,
        http_codes: [
          [200],
          [403, 'User invalid or forbidden']
        ]
      )
      params do
        requires :email, regexp: /.+@.+/, allow_blank: false
        requires :password, allow_blank: false
      end
      get :token do
        user = User.find_by email: params[:email]
        error!('User is not active', 403) unless user.status == :active
        error!('Invalid password', 403) unless user.password == params[:password]
        user.generate_new_login_token
        user.reload
        present user, with: UserRepresenter
      end

      desc 'Verify an existing user based on their token or API key', hidden: true
      get :verify do
        authenticate!
        present current_user, with: UserRepresenter
      end
    end
  end
end
