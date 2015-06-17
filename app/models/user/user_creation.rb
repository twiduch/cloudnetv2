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
    @api = OnappAPI.admin_connection
    create_onapp_user
    generate_encrypted_onapp_api_key
    generate_encrypted_confirmation_token
    # Send confirmation email
    Email.welcome(self).deliver
  end

  def create_onapp_user
    credentials = generate_onapp_user_credentials
    onapp_user = @api.post(:users, body: credentials).user
    update_attributes!(
      id: onapp_user.id,
      status: :pending
    )
  end

  def generate_onapp_user_credentials
    username = find_unique_onapp_username
    {
      user: {
        login: username,
        email: "#{username}@cloud.net",
        password: generate_onapp_password,
        role_ids: [Cloudnet.onapp_cloudnet_role]
      }
    }
  end

  def generate_encrypted_onapp_api_key
    api_key = @api.post("users/#{id}/make_new_api_key").user.api_key
    update_attributes! encrypted_onapp_api_key: SymmetricEncryption.encrypt(api_key)
  end

  def find_unique_onapp_username
    10.times do
      cut_name = full_name.gsub(' ', '-').downcase.tr('^a-z\-', '')[0..USERNAME_SIZE]
      username = "#{cut_name}_#{SecureRandom.hex(3)}"
      # Check in case this username already exists on OnApp
      response = @api.post 'users/validate_login', body: { login: username }
      return username if response.valid
    end
  end

  # OnApp passwords must conform to OnApp's requirements of 1 special char, 1 uppper, 1 lower and
  # 1 number.
  def generate_onapp_password
    # Define the types of characters required by the OnApp API
    symbols = '&()*%$!'.split ''
    lower = ('a'..'z').to_a
    upper = ('A'..'Z').to_a
    numbers = (1..9).to_a
    types = [symbols, lower, upper, numbers]
    all = types.flatten
    # Take 1 random character from each group to ensure we meet OnApp's requirements
    required = types.map(&:sample)
    # Fill the rest of the password with random samplings from the all groups
    fill = (0...PASSWORD_SIZE - 4).map { all.sample }
    (required + fill).shuffle.join
  end

  # Generate a confirmation token for a URL that a user can click to confirm their account
  def generate_encrypted_confirmation_token
    token = SecureRandom.hex(10)
    update_attributes! encrypted_confirmation_token: SymmetricEncryption.encrypt(token)
  end

  # Unique link which a user receives in their email and clicking it confirms their account
  def confirmation_url
    fail 'User already confirmed.' if status == :active
    "#{Cloudnet.hostname}/auth/confirm?token=#{confirmation_token}"
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
