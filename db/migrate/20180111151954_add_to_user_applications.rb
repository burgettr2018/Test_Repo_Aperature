class AddToUserApplications < ActiveRecord::Migration
  def change
    add_column :user_applications, :postpone_invite, :boolean
    add_column :user_applications, :assigned_to_id, :integer
    add_column :user_applications, :form_submit_id, :integer
    add_column :user_applications, :request_status, :string
  end
end
