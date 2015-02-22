module Routes
  # /datacentres
  class Datacentres < Grape::API
    resource :datacentres do
      desc 'List all datacentres'
      get do
        present Datacentre.all
      end
    end
  end
end
