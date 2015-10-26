module Routes
  # /servers
  class Servers < Grape::API
    resource :servers do
      before do
        authenticate!
      end

      desc 'List all servers'
      get do
        current_user.servers
      end

      desc 'Create a server'
      params do
        requires :template, type: Integer, desc: "ID of template taken from 'GET /templates'"
        optional :name, type: String, desc: 'Human-readable name for server'
        optional :hostname, type: String, desc: 'OS-compatible hostname'
        optional :memory, type: Integer, desc: 'Amount of memory in MBs'
        optional :disk_size, type: Integer, desc: 'Size of primary disk in GBs'
      end
      post do
        server = Server.new(user: current_user).provision params
        present server, with: ServerRepresenter
      end

      params do
        requires :id, type: String, desc: 'Server ID'
      end
      route_param :id do
        desc 'Destroy a server'
        delete do
          Server.find(params[:id]).deprovision
          { message: "Server #{params[:id]} has been scheduled for destruction" }
        end

        desc 'Show information about a server'
        get do
          present Server.find params[:id], with: ServerRepresenter
        end
      end
    end
  end
end
