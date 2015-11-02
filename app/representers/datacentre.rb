require_relative 'base'
require_relative 'template'

# Serialise datacentre objects
module DatacentreRepresenter
  include BaseRepresenter

  property :id, type: String
  property :created_at
  property :updated_at
  property :label
  property :coords
  collection :templates, extend: TemplateRepresenter
end

# For representing more than one at a time
module DatacentresRepresenter
  include BaseRepresenter
  include Representable::JSON::Collection
  items extend: DatacentreRepresenter
end
