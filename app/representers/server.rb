require_relative 'base'

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
  property :state
  property :template, extend: TemplateRepresenter
end

# For representing more than one at a time
module ServersRepresenter
  include BaseRepresenter
  include Representable::JSON::Collection
  items extend: ServerRepresenter
end
