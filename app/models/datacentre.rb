# A datacentre is a provider of cloud resources. It is brokered through the Federation.
class Datacentre
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Mongoid::History::Trackable

  has_many :templates

  # Override Mongoid's IDs and use Onapp's unique hypervisor_group_id
  field :_id, type: Integer, overwrite: true
  alias_attribute :onapp_identifier, :_id

  field :label

  # [lat, long] for the datacentre's position on the planet
  field :coords, type: Array

  track_history(
    track_create: true,
    track_update: true,
    track_destroy: true
  )

  class << self
    # Basically asking if UpdateFederationResources.run() has been run
    def synchronised?
      Datacentre.count > 0 && Template.count > 0
    end
  end
end
