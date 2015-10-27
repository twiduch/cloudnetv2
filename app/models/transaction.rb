# A selective representation of Onapp's transactions logs. Contains things like server events and
# server resource usages. It is the primary means by which state is synced with OnApp
class Transaction
  include Mongoid::Document
  include Mongoid::Timestamps

  # Override Mongoid's IDs and use Onapp's unique ID
  field :_id, type: String, overwrite: true
  alias_attribute :onapp_identifier, :_id

  # The cloud.net ID of the resource
  field :identifier

  # Most likely server, or could be DNS in the future
  field :resource, type: Symbol

  # Typically a server build event, or server usage stats
  field :type, type: Symbol

  # The specifics of what happened. Eg. exactly how much bandwidth was used in that transaction
  field :details
end
