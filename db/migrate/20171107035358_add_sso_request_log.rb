class AddSsoRequestLog < ActiveRecord::Migration
  def change
    create_table :sso_request_logs do |t|
      t.datetime :time
      t.references :oauth_application, index: true
      t.references :user, index: true
      t.string :access_token
      t.jsonb :params
      t.string :ip
      t.string :trace_id
      t.boolean :is_active
    end
    add_foreign_key :sso_request_logs, :oauth_applications
    add_foreign_key :sso_request_logs, :users
    add_index :sso_request_logs, :access_token
  end
end
