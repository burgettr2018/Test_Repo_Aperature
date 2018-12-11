class CreateImpersonationLogs < ActiveRecord::Migration
  def change
    create_table :impersonation_logs do |t|
      t.integer :user_id, null: false
      t.integer :impersonated_user_id, null: false
      t.datetime :started_at
      t.datetime :ended_at
      t.timestamps
    end
    add_index :impersonation_logs, :user_id
    add_index :impersonation_logs, :impersonated_user_id
  end
end
