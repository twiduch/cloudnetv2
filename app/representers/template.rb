require_relative 'base'

# Serialise template objects
module TemplateRepresenter
  include BaseRepresenter

  property :id, type: String
  property :created_at
  property :updated_at
  property :label
  property :os
  property :os_distro
  property :min_memory_size
  property :min_disk_size
  property :price
end
