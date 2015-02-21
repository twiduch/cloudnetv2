# Store for various global system state.
# Eg, the transactions log marker that keeps track of at one point we are in consuming the
# transactions log
class System
  include Mongoid::Document

  DEFAULTS = {}

  field :key
  field :value

  validates_presence_of :key, :value
  validates_uniqueness_of :key

  def self.get(key)
    key = key.to_s
    find_by(key: key).value
  rescue Mongoid::Errors::DocumentNotFound
    # See if setting is in DEFAULTS otherwise return ''
    DEFAULTS.fetch key, ''
  end

  def self.set(key, value)
    key = key.to_s
    find_by(key: key).update_attributes! key: key, value: value
  rescue Mongoid::Errors::DocumentNotFound
    create key: key, value: value
  end
end
