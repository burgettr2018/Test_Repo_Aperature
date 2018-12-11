class AddApiRequestLogTable < ActiveRecord::Migration
  def change
    create_table :api_request_logs do |t|
      t.datetime :time
      t.string :method
      t.string :format
      t.string :url
      t.string :status
      t.string :ip
      t.string :query_params
      t.string :raw_request_body
      t.string :parsed_request_body
      t.string :response
    end
  end
end
