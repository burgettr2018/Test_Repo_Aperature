class AddApplicationDataToUserApplications < ActiveRecord::Migration
  def change
    add_column :user_applications, :application_data, :jsonb
  end
end
