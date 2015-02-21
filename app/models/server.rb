# This is what it's all about. Machines in the cloud!
# A server on cloud.net should be exactly synced to a server on the Onapp API
class Server
  include Mongoid::Document
  include Mongoid::Timestamps
  include OnappAPI

  belongs_to :datacentre
  belongs_to :user
  has_one :template

  # Override Mongoid's IDs and use Onapp's unique ID
  field :_id, overwrite: true

  # Human name for server
  field :name

  field :hostname

  # Possible values: :pending, :building, :starting_up, :rebooting, :shutting_down, :on, :off
  field :state, type: Symbol, default: :building

  field :built, type: Boolean, default: false
  field :locked, type: Boolean, default: true
  field :suspended, type: Boolean, default: true

  field :cpus, type: Integer
  field :memory, type: Integer
  field :disk_size, type: Integer
  field :bandwidth, type: Float, default: 0.0

  field :ip_address
  field :root_password

  # Make a note of the user's IP address when destroyed
  field :ip_of_user_at_destruction
end
