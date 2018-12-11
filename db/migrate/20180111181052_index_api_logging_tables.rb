class IndexApiLoggingTables < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute("TRUNCATE TABLE api_request_logs")

    add_index :api_request_logs, :access_token
    add_index :api_request_logs, :status
    add_index :api_request_logs, :method
    add_index :api_request_logs, :time

    add_index :external_api_request_logs, :status
    add_index :external_api_request_logs, :method
    add_index :external_api_request_logs, :time
  end
end
