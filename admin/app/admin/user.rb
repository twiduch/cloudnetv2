ActiveAdmin.register User do
  permit_params :email, :full_name

  index do
    selectable_column
    id_column
    column :full_name
    column :email
    column :created_at
    actions
  end

  filter :email, as: :string
  filter :full_name, as: :string

  controller do
    def find_resource
      User.find params[:id].to_i
    end
  end
end
