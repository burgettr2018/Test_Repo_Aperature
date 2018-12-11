class AddOktaSamlIdentityProvider < ActiveRecord::Migration
  def self.up
    provider = SamlIdentityProvider.find_or_initialize_by(name: 'Okta', token: 'okta', name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress', issuer: "#{ENV['UMS_OC_OAUTH_HOST']}/users/auth/okta/callback")
    provider.save(validate: false)
  end

  def self.down
    SamlIdentityProvider.where(token: 'okta').destroy_all
  end
end
