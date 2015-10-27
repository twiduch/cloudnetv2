require 'grape-roar'
require 'roar/representer'
require 'roar/coercion'
require 'roar/json'
require 'roar/json/hal'

# Parent properties inherited by all other representers
module BaseRepresenter
  extend ActiveSupport::Concern
  included do
    include Roar::JSON
    include Roar::Hypermedia
    include Roar::Coercion
    include Grape::Roar::Representer
  end
end
