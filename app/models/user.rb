# A cloud.net user. Should map and sync to an Onapp user
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include OnappAPI

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

  field :resource_limits, default: DEFAULT_LIMITS
end
