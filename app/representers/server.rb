# Serialise server objects
module ServerRepresenter
  include BaseRepresenter

  property :id, type: String
  property :created_at
  property :updated_at
  property :name
  property :hostname
  property :memory
  property :cpus
  property :disk_size
end
