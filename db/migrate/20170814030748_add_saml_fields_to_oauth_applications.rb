class AddSamlFieldsToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :saml_issuer, :string
    add_column :oauth_applications, :saml_logout_url, :string
    add_index :oauth_applications, :saml_issuer, unique: true
  end
end
