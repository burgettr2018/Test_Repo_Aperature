class AddApplicationToApiRequestLogs < ActiveRecord::Migration
  def change
    add_column :api_request_logs, :oauth_application_id, :integer
    add_index :api_request_logs, :oauth_application_id
    add_foreign_key :api_request_logs, :oauth_applications, column: :oauth_application_id
    ApiRequestLog.update_all(oauth_application_id: OauthApplication.find_by_name('UMS').id)
    change_column_null :api_request_logs, :oauth_application_id, false
  end
end
