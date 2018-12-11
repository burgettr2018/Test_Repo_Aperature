class AddSsoRedirectTokens < ActiveRecord::Migration
  def change
    create_table :sso_redirects do |t|
      t.references :oauth_application, index: true
      t.string :token, null: false
      t.string :path, null: false
    end
    add_index :sso_redirects, [:oauth_application_id, :token], unique: true

    add_column :oauth_applications, :sso_token, :string
    add_index :oauth_applications, :sso_token, unique: true


  end
end
