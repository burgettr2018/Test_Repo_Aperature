class AddExternalApiRequestLog < ActiveRecord::Migration
  def change
    create_table :external_api_request_logs do |t|
      t.datetime :time
      t.string :method
      t.string :format
      t.string :url
      t.string :status
      t.jsonb :request_headers
      t.jsonb :query_params
      t.string :request_body
      t.jsonb :response_headers
      t.string :response
      t.string :trace_id
      t.string :access_token
    end
  end
end
