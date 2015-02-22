module Routes
  # /datacentres
  class Datacentres < Grape::API
    resource :datacentres do
      desc 'List all datacentres'
      get do
        Datacentre.includes(:templates).map(&:templates)
      end
    end
  end
end
