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
  field :status, default: :pending
  field :resource_limits, default: DEFAULT_LIMITS

  field :onapp_api_key

  validates_uniqueness_of [:id, :email]
  validates_presence_of [:email, :full_name]

  class << self
    # This is the canonical means for creating a cloud.net user. Unless you are creating fake
    # users for testing purposes, in which case using factories is fine.
    def create_with_synced_onapp_user(attributes)
      user = User.new attributes
      fail Mongoid::Errors::Validations.new(user), 'Validation exception' unless user.valid?
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
  end
end
