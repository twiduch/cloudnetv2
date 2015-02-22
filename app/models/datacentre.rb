# A datacentre is a provider of cloud resources. It is brokered through the Federation.
class Datacentre
  include Mongoid::Document

  has_many :templates

  # Override Mongoid's IDs and use Onapp's unique hypervisor_group_id
  field :_id, overwrite: true

  field :label

  # [lat, long] for the datacentre's position on the planet
  field :coords, type: Array

  def entity
    Entity.new(self)
  end

  # How to present the object when requested through the API
  class Entity < Grape::Entity
    expose :_id, :label, :coords, :templates
  end
end
