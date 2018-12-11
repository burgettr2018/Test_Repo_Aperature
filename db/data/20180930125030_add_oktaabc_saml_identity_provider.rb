class AddOktaabcSamlIdentityProvider < ActiveRecord::Migration
  def self.up
    provider = SamlIdentityProvider.find_or_initialize_by(name: 'ABC Supply Okta', token: 'oktaabc', name_identifier_format: 'urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress', issuer: "#{ENV['UMS_OC_OAUTH_HOST']}/users/auth/oktaabc/callback", idp_cert: "#{ENV['OKTA_ABC_IDP_CERT']}", idp_sso_target_url: "#{ENV['OKTA_ABC_IDP_SSO_TARGET_URL']}", idp_cert_fingerprint: "#{ENV['OKTA_ABC_IDP_CERT_FINGERPRINT']}" )
    provider.save(validate: false)
  end

  def self.down
    SamlIdentityProvider.where(token: 'oktaabc').destroy_all
  end
end
