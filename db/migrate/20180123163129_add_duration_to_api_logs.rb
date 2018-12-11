class AddDurationToApiLogs < ActiveRecord::Migration
  def change
    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE api_request_logs")

    add_column :api_request_logs, :duration_ms, :integer
    #add_index :api_request_logs, :duration_ms

    #ActiveRecord::Base.connection.execute("TRUNCATE TABLE external_api_request_logs")

    add_column :external_api_request_logs, :duration_ms, :integer
    add_index :external_api_request_logs, :duration_ms
  end
end
