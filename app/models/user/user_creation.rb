# Methods associated with user creation.
# Every user on cloud.net must have a corresponding user with OnApp. It would also be possible
# for cloud.net to only ever have a single admin user and create all resources on behalf of
# cloud.net users, but that would fail to take advantage of OnApp's user isolation, which makes
# it harder for malicious users to access the networks of other users.
# See http://onapp.com/cloud/features/security/ for more info.
module UserCreation
  extend ActiveSupport::Concern

  USERNAME_SIZE = 10
  PASSWORD_SIZE = 16

  # We create the attributes for the OnApp user here and send them over using the OnApp API.
  # The only thing we retain from the response is the OnApp ID for future auditing/debugging etc.
  # Future interaction with the API occurs through their own unique API key.
  def create_onapp_user_and_save
    create_onapp_user
    generate_token_for :confirmation_token
    generate_token_for :cloudnet_api_key
    # Send confirmation email
    Email.welcome(self).deliver
  end

  def create_onapp_user
    credentials = generate_onapp_user_credentials
    onapp_user = OnappAPI.admin(:post, '/users', body: credentials)['user']
    update_attributes!(
      id: onapp_user['id'],
      onapp_password: credentials[:user][:password],
      onapp_username: credentials[:user][:login],
      status: :pending
    )
  end

  def generate_onapp_user_credentials
    username = find_unique_onapp_username
    {
      user: {
        login: username,
        email: "#{username}@cloud.net",
        password: System.generate_onapp_password(PASSWORD_SIZE),
        role_ids: [Cloudnet.onapp_cloudnet_role]
      }
    }
  end

  def find_unique_onapp_username
    10.times do
      cut_name = full_name.tr(' ', '-').downcase.tr('^a-z\-', '')[0..USERNAME_SIZE]
      username = "#{cut_name}_#{SecureRandom.hex(3)}"
      # Check in case this username already exists on OnApp
      response = OnappAPI.admin :post, '/users/validate_login', body: { login: username }
      return username if response['valid']
    end
  end

  # Generate a confirmation token for a URL that a user can click to confirm their account
  def generate_token_for(attribute)
    token = SecureRandom.urlsafe_base64
    update_attributes! attribute => token
  end

  # Unique link which a user receives in their email and clicking it confirms their account
  def confirmation_url
    fail 'User already confirmed.' if status == :active
    "http://www.#{Cloudnet.hostname}/auth/confirm?token=#{confirmation_token}"
  end

  class_methods do
    # Confirm a user based on confirmation token
    def confirm_from_token(token, password)
      encrypted_token = SymmetricEncryption.encrypt token
      begin
        user = User.find_by encrypted_confirmation_token: encrypted_token
        user.password = password # BCrypt's the password
        user.status = :active
        user.confirmation_token = nil
        user.save!
      rescue Mongoid::Errors::DocumentNotFound
        false
      end
    end
  end
end
