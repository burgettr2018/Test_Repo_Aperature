class CreateSamlIdentityProviders < ActiveRecord::Migration
  def change
    create_table :saml_identity_providers do |t|
      t.string :name
      t.string :token
      t.string :issuer
      t.string :idp_sso_target_url
      t.string :idp_cert
      t.string :idp_cert_fingerprint
      t.string :name_identifier_format

      t.timestamps null: false
    end
    add_index :saml_identity_providers, :name
    add_index :saml_identity_providers, :token
  end
end
