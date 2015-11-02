# Serialise user objects
module UserRepresenter
  include BaseRepresenter

  property :id, type: Integer
  property :created_at
  property :updated_at
  property :full_name
  property :cloudnet_api_key
  property :login_token
  property :status
  property :resource_limits
end
