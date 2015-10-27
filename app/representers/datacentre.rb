require_relative 'base'

# Serialise datacentre objects
module DatacentreRepresenter
  include BaseRepresenter

  property :id, type: String
  property :created_at
  property :updated_at
  property :label
  collection :templates, extend: TemplateRepresenter
end

# For collections
module DatacentresRepresenter
  include BaseRepresenter
  collection :to_a, extend: DatacentreRepresenter, as: :datacentres, embedded: true
end
