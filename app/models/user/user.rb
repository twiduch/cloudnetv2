require 'app/models/user/user_creation'

# A cloud.net user. Should map and sync to an Onapp user
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ModelProxy
  include OnappAPI
  include UserCreation

  has_many :servers

  # The upper limits for total server resources that the user can have
  DEFAULT_LIMITS = {
    vm_max: 6,
    memory_max: 8192,
    cpu_max: 4,
    storage_max: 120,
    bandwidth_max: 1024
  }

  # Override Mongoid's IDs and use Onapp's unique ID
  field :_id, overwrite: true

  field :email
  field :full_name
  field :admin, type: Boolean, default: false
  field :status, type: Symbol, default: :pending
  field :resource_limits, default: DEFAULT_LIMITS

  field :hashed_password

  # SYMMETRICALLY ENCRYPTED (because they need to be retrieved/queried)
  # For connecting to the user's own OnApp API account
  field :encrypted_onapp_api_key, encrypted: true
  # Short-lived login token for use with the HTML frontend
  field :encrypted_login_token, encrypted: true
  # More permanent API key
  field :encrypted_cloudnet_api_key, encrypted: true
  # To confirm registration
  field :encrypted_confirmation_token, encrypted: true

  validates_uniqueness_of [:id, :email]
  validates_presence_of [:email, :full_name]

  # Fetch or return a Bcrypt instance of the hashed password.
  # NB: A BCrypt hash instance can be compared to a plain text string with `==`
  def password
    @password ||= BCrypt::Password.new(hashed_password)
  end

  # Bcrypt hash the password
  def password=(new_password)
    @password = BCrypt::Password.create(new_password)
    self[:hashed_password] = @password
  end

  def generate_new_login_token
    token = SecureRandom.hex(10)
    update_attributes! encrypted_login_token: SymmetricEncryption.encrypt(token)
    token
  end

  class << self
    # This is the canonical means for creating a cloud.net user. Unless you are creating fake
    # users for testing purposes, in which case using factories is fine.
    def create_with_synced_onapp_user(attributes)
      user = User.new attributes
      unless user.valid?
        fail Mongoid::Errors::Validations.new(user), 'User validation failed'
      end
      user.worker.create_onapp_user_and_save
    end

    # Create the non-privileged OnApp user role that all cloud.net users use to interact with OnApp
    # NB. This should only need to be done when setting up cloud.net for the first time.
    def create_onapp_role
      OnappAPI.admin_connection.post(
        :roles,
        body: {
          role: {
            label: 'user',
            permission_ids: Cloudnet::ONAPP_USER_PERMISSIONS
          }
        }
      ).role.id
    end

    # Check the incoming API request headers for a valid authentication credential
    def authorize(auth_header)
      type = auth_header.split[0].strip
      credential = auth_header.split[1].strip
      case type
      when 'TOKEN'
        User.find_by encrypted_login_token: SymmetricEncryption.encrypt(credential)
      when 'APIKEY'
        User.find_by encrypted_cloudnet_api_key: SymmetricEncryption.encrypt(credential)
      else
        false
      end
    end
  end
end
