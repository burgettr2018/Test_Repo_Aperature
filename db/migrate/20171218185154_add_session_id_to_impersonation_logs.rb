class AddSessionIdToImpersonationLogs < ActiveRecord::Migration
  def change
    add_column :impersonation_logs, :session_id, :string
  end
end
