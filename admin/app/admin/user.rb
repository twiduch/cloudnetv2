ActiveAdmin.register User do
  permit_params :email, :full_name, :status

  index do
    selectable_column
    id_column
    column :full_name
    column :email
    column :created_at
    actions defaults: true do |user|
      link_to 'Activity', activity_user_path(user)
    end
  end

  filter :email, as: :string
  filter :full_name, as: :string

  controller do
    def find_resource
      User.find params[:id].to_i
    end
  end

  form do |f|
    f.inputs do
      f.input :full_name
      f.input :email
      f.input :status, as: :select, collection: [:active, :pending, :suspended]
    end
    actions
  end

  member_action :activity, method: :get do
    user_id = params[:id]
    @activity = HistoryTracker.concerning_user user_id
  end
end
