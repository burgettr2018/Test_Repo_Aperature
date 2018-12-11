class AddTraceidToRequestLog < ActiveRecord::Migration
  def change
    add_column :api_request_logs, :trace_id, :string
  end
end
