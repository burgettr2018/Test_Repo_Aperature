class RemoveCurrentSsoLogToUser < ActiveRecord::Migration
  def change
    remove_foreign_key :users, column: :current_sso_request_log_id
    remove_column :users, :current_sso_request_log_id
  end
end
