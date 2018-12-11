class AddApiTokenToApiRequestLogs < ActiveRecord::Migration
  def change
    add_column :api_request_logs, :access_token, :string
  end
end
