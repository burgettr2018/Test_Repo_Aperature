require 'doorkeeper/orm/active_record/application'
class OauthApplication < Doorkeeper::Application
  nilify_blanks

  has_many :application_permissions, dependent: :destroy
  has_many :permission_types, dependent: :destroy
  has_many :user_applications, dependent: :destroy

  has_many :maintenance_messages, dependent: :destroy

  has_many :api_tokens, through: :authorized_tokens

  has_many :active_maintenance_messages, -> { active }, class_name: :MaintenanceMessage

  #
	# def long_life_tokens_view_model
	# 	OpenStruct.new(
	# 						uid: self.uid,
	# 						secret: self.secret,
	# 						tokens: long_life_tokens
	# 	)
	# end

  rails_admin do
		# show do
		# 	configure :long_life_tokens do
		# 		label 'API Tokens'
		# 		show
		# 		pretty_value do
		# 			bindings[:view].render({
		# 																 partial: "rails_admin/main/show_access_token",
		# 																 locals: {:field => self, :form => bindings[:form], variable: value}
		# 														 }).html_safe
		# 		end
		# 	end
		# end
    edit do
      exclude_fields :uid, :secret, :permission_types, :application_permissions, :api_tokens, :maintenance_messages, :active_maintenance_messages, :user_applications
      field :logout_url do
        help 'Optional - if set logout will attempt to open in hidden frame to log out of remote sessions'
      end
    end
  end

  def friendly_uid
    name.parameterize.underscore
  end

  def application_uri
    if self.saml_acs.present?
      request = "<saml2p:AuthnRequest
        xmlns:saml2p=\"urn:oasis:names:tc:SAML:2.0:protocol\"
        xmlns:saml2=\"urn:oasis:names:tc:SAML:2.0:assertion\"
        Version=\"2.0\"
        IssueInstant=\"#{Time.now.utc.iso8601}\"
        AssertionConsumerServiceURL=\"#{self.saml_acs}\">
        <saml2:Issuer>#{self.saml_issuer}</saml2:Issuer>
        <saml2p:RequestedAuthnContext>
          <saml2:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</saml2:AuthnContextClassRef>
        </saml2p:RequestedAuthnContext>
      </saml2p:AuthnRequest>"
      zstream  = Zlib::Deflate.new(Zlib::DEFAULT_COMPRESSION, -Zlib::MAX_WBITS)
      request = Base64.strict_encode64(zstream.deflate(request, Zlib::FINISH))
      #ID=\"_fa52349d-902b-4d2d-b1d2-5774ff67fd5e\"
      #  Destination=\"https://login-devel.owenscorning.com/users/saml/sso\"
      "/users/saml/sso?SAMLRequest=#{CGI.escape request}"
    else
      self[:application_uri]
    end
  end

  def real_application_uri
    self[:application_uri]
  end

end
