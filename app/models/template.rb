# Describes how to build a server. basically what OS to use.
# Can only be updated by UpdateFederationResources
class Template
  include Mongoid::Document

  belongs_to :datacentre

  # Override Mongoid's IDs and use Onapp's unique ID
  field :_id, overwrite: true

  # Eg; 'Arch Linux 2012.08 x86'
  field :label

  # Eg; 'linux'
  field :os

  # Eg; 'archlinux'
  field :os_distro

  # Minimum resurces required for server to handle the template
  field :min_memory_size
  field :min_disk_size

  # Used for licensed Oss like Windows
  field :price
end
