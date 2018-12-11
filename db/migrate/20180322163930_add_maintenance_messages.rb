class AddMaintenanceMessages < ActiveRecord::Migration
  def change
    create_table :maintenance_messages do |t|
      t.belongs_to :oauth_application
      t.datetime :start_date_utc
      t.datetime :end_date_utc
      t.string :message
      t.integer :created_by_id, index: true
    end

    add_foreign_key :maintenance_messages, :users, column: :created_by_id
    add_foreign_key :maintenance_messages, :oauth_applications
  end
end
