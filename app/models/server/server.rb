require 'app/models/server/interactions'

# This is what it's all about. Machines in the cloud!
# A server on cloud.net should be exactly synced to a server on the Onapp API
class Server
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Mongoid::History::Trackable
  include ModelWorkerSugar
  include OnappAPI
  include Interactions

  belongs_to :user
  belongs_to :template

  # We can't assign this value to Mongoid's ID because that would mean that the API would not be able to
  # instantaneously respond (it would have to wait for the CP to return a response). This way our API can respond
  # with our own ID with which a user can then track the progress of the server.
  field :onapp_identifier, type: String

  # Human name for server
  field :name

  field :hostname

  # Possible values: :pending, :building, :starting_up, :rebooting, :shutting_down, :on, :off
  field :state, type: Symbol, default: :building

  field :built, type: Boolean, default: false
  field :locked, type: Boolean, default: true
  field :suspended, type: Boolean, default: true

  field :cpus, type: Integer, default: 1
  field :memory, type: Float, default: 512
  field :disk_size, type: Integer, default: 20
  field :bandwidth, type: Float, default: 0.0

  field :ip_address
  field :root_password

  validates_presence_of :user, :template, :name, :hostname

  validate do |server|
    if disk_size <= server.template.min_disk_size + ((server.memory / 1024) * 2)
      errors.add(
        :base,
        "Disk size must be greater than required OS size (#{server.template.min_disk_size}GB) " \
        "plus swap size (twice the size of RAM, ie. #{memory / 1024}GB)"
      )
    end
  end

  track_history(
    track_create: true,
    track_update: true,
    track_destroy: true
  )

  def required_swap
    # Use rule of thumb that *NIX needs twice as much swap as RAM
    template.os == 'windows' ? 0 : (memory / 1024) * 2
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def prepare_onapp_params
    params = {
      label: name,
      hypervisor_group_id: template.datacentre.id,
      hostname: hostname,
      memory: memory,
      cpus: cpus,
      cpu_shares: 100,
      primary_disk_size: disk_size - required_swap,
      swap_disk_size: required_swap,
      template_id: template.id,
      required_virtual_machine_build: 1,
      required_virtual_machine_startup: 1,
      required_ip_address_assignment: 1,
      note: 'Created with Cloud.net'
    }

    params.merge!(rate_limit: location.network_limit) if template.datacentre.try(:network_limit).to_i > 0
    params.merge!(licensing_type: 'mak') if template.os.include?('windows') || template.os_distro.include?('windows')
    params
  end

  def create_onapp_server
    response = onapp.api(:post, virtual_machine: prepare_onapp_params)['virtual_machine']
    self.onapp_identifier = response['identifier']
    save!
  end

  def destroy_onapp_server
    # Destroy the OnApp server
    onapp.api :delete
    # Soft delete the cloud.net server
    delete
  end

  # Acrchive of build, reboot, disk build, activity
  def transactions
    Transaction.where(resource: :server, identifier: onapp_identifier)
  end
end
