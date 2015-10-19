# Describes how to build a server. basically what OS to use.
# Can only be updated by UpdateFederationResources
class Template
  include Mongoid::Document

  belongs_to :datacentre
  has_many :servers

  # Override Mongoid's IDs and use Onapp's unique ID
  field :_id, overwrite: true

  # Eg; 'Arch Linux 2012.08 x86'
  field :label

  # Eg; 'linux'
  field :os

  # Eg; 'archlinux'
  field :os_distro

  # Minimum resources required for server to handle the template
  field :min_memory_size, type: Float, default: 1
  field :min_disk_size, type: Float, default: 10

  # Used for licensed OSs like Windows
  field :price, type: Float, default: 0.0

  validates_presence_of :label, :os, :os_distro

  class << self
    def find_an_ubuntu_template
      Template.all.to_a.find { |t| t.os_distro =~ /ubuntu/ }
    end
  end
end
