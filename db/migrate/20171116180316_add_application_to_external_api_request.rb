class AddApplicationToExternalApiRequest < ActiveRecord::Migration
  def change
    add_column :external_api_request_logs, :oauth_application_id, :integer
    add_index :external_api_request_logs, :oauth_application_id
    add_foreign_key :external_api_request_logs, :oauth_applications, column: :oauth_application_id
    ExternalApiRequestLog.update_all(oauth_application_id: OauthApplication.find_by_name('UMS').id)
    change_column_null :external_api_request_logs, :oauth_application_id, false
  end
end
