require_relative 'base'
require_relative 'template'

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
  collection :transactions do
    property :created_at, as: :date
    property :details
  end
end

# For representing more than one at a time
module ServersRepresenter
  include BaseRepresenter
  include Representable::JSON::Collection
  items extend: ServerRepresenter
end
