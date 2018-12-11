FactoryBot.define do
  factory :saml_request, class: String do
    skip_create
    transient do
      acs { nil }
    end
    initialize_with {
      nil and return unless acs
      saml_settings = OneLogin::RubySaml::Settings.new
      saml_settings.assertion_consumer_service_url = acs
      saml_request = OneLogin::RubySaml::Authrequest.new
      params = saml_request.create_params(saml_settings)
      params['SAMLRequest']
    }
  end
end

