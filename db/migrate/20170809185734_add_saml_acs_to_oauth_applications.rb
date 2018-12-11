class AddSamlAcsToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :saml_acs, :string
    add_index :oauth_applications, :saml_acs, unique: true
  end
end
