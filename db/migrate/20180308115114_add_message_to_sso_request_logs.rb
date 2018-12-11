class AddMessageToSsoRequestLogs < ActiveRecord::Migration
  def change
    add_column :sso_request_logs, :message, :string
    add_column :sso_request_logs, :is_success, :boolean, index: true

    # previously we only inserted on success
    SsoRequestLog.update_all(is_success: true)
  end
end
