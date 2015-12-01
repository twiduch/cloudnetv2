ActiveAdmin.register Server do
  permit_params :name, :hostname, :suspended

  index do
    selectable_column
    column 'OnApp Identifier' do |server|
      link_to server.onapp_identifier, "#{ENV['ONAPP_URI']}/virtual_machines/#{server.onapp_identifier}"
    end
    column :name
    column :hostname
    column :created_at
    actions
  end

  controller do
    def find_resource
      Server.find params[:id]
    end
  end

  form do |f|
    f.inputs do
      f.input :name
      f.input :hostname
      f.input :suspended, as: :radio
    end
    actions
  end
end
