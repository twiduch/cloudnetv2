ActiveAdmin.register Datacentre do
  permit_params :label, :coords

  index do
    selectable_column
    id_column
    column :label
    column :coords
    column :created_at
    actions
  end

  controller do
    def find_resource
      Datacentre.find params[:id].to_i
    end
  end
end
