class AddCurrentSsoLogToUser < ActiveRecord::Migration
  def change
    add_column :users, :current_sso_request_log_id, :integer
    add_foreign_key :users, :sso_request_logs, column: :current_sso_request_log_id
  end
end
