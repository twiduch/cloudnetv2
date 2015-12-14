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

  def self.get(key, default: '')
    key = key.to_s
    find_by(key: key).value
  rescue Mongoid::Errors::DocumentNotFound
    # See if setting is in DEFAULTS otherwise return ''
    DEFAULTS.fetch key, default
  end

  def self.set(key, value)
    key = key.to_s
    find_by(key: key).update_attributes! key: key, value: value
  rescue Mongoid::Errors::DocumentNotFound
    create key: key, value: value
  end

  class << self
    # OnApp passwords must conform to OnApp's requirements of 1 special char, 1 uppper, 1 lower and
    # 1 number.
    def generate_onapp_password(password_length = 12)
      # Define the types of characters required by the OnApp API
      symbols = '&()*%$!'.split ''
      lower = ('a'..'z').to_a
      upper = ('A'..'Z').to_a
      numbers = (1..9).to_a
      types = [symbols, lower, upper, numbers]
      all = types.flatten
      # Take 1 random character from each group to ensure we meet OnApp's requirements
      required = types.map(&:sample)
      # Fill the rest of the password with random samplings from the all groups
      fill = (0...password_length - 4).map { all.sample }
      (required + fill).shuffle.join
    end
  end
end
