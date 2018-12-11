class AddContextToApiRequestLog < ActiveRecord::Migration
  def change
    add_column :api_request_logs, :context_hash, :jsonb
    add_column :api_request_logs, :request_format, :string
  end
end
