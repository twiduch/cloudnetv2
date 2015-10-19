# Serialise server objects
module ServerRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::Coercion
  include Grape::Roar::Representer

  property :id, type: String
  property :created_at
  property :updated_at
  property :name
  property :hostname
  property :memory
  property :cpus
  property :disk_size
end
