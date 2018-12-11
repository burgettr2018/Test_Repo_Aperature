class SessionsController < Devise::SessionsController
  include SamlIdp::Controller
  include OktaCookieHelper
	include ExternalSsoHelper
	skip_before_action :verify_authenticity_token, only: [:saml]

  before_action :set_referer_view_path, only: [:new]
  layout :referrer_sign_in_layout, only: [:new]

	def validate_saml_request
		super
		if @saml_request.blank?
      #Hack -- if @saml_request didn't get set, the parent class tries to use zlib.inflate, however for SAP TM portal the SAMLRequest is not compressed, below fixes that issue
			@saml_request =Base64.decode64(params[:SAMLRequest] || cookies[:SAMLRequest])
			@saml_request_id = @saml_request[/ID=['"](.+?)['"]/, 1]
			@saml_acs_url = @saml_request[/AssertionConsumerServiceURL=['"](.+?)['"]/, 1]
		end

		xml = Nokogiri::XML(@saml_request)
		if xml.root.present?
			@saml_request_type = xml.root.name.to_s
			@saml_issuer = xml.at_xpath('//t:Issuer', 't' => 'urn:oasis:names:tc:SAML:2.0:assertion').try(:text).to_s
		else
			@saml_request_type = nil
			@saml_request = nil
			@saml_request_id = nil
			@saml_acs_url = nil
			@saml_issuer = nil
		end
	end

  def saml

		response.headers["X-FRAME-OPTIONS"] = "ALLOW-FROM https://flpnwc-dedc28e54.dispatcher.us2.hana.ondemand.com"
		response.headers["X-FRAME-OPTIONS"] = "ALLOW-FROM https://qtmcollaborationportal-dedc28e54.dispatcher.us2.hana.ondemand.com"
		response.headers["X-FRAME-OPTIONS"] = "ALLOW-FROM https://carrierportal.owenscorning.com"
		response.headers["Content-Security-Policy"] = "frame-ancestors https://qtmcollaborationportal-dedc28e54.dispatcher.us2.hana.ondemand.com"
		response.headers["Content-Security-Policy"] = "frame-ancestors https://flpnwc-dedc28e54.dispatcher.us2.hana.ondemand.com"
		response.headers["Content-Security-Policy"] = "frame-ancestors https://carrierportal.owenscorning.com"

	  
	  
		validate_saml_request
		if @saml_request_type == 'LogoutRequest'
			#SLO
			saml_slo
		else
			#SSO

			if validate_saml_acs
				session.delete(:return_to)
				if user_signed_in?
					Rails.logger.info "user already signed in: #{current_user.inspect}"
					Rails.logger.info @saml_request.inspect if ENV['UMS_DEBUG_SAML'].to_b
					@saml_response = encode_SAMLResponse(current_user['email'], issuer_uri: idp_landing_url, session_not_on_or_after: 2.hours.from_now,  audience_uri:@saml_request[/Issuer>(.+?)</, 1] )

					@application = OauthApplication.find_by_saml_acs(@saml_acs_url) if @saml_acs_url.present? #TODO , check using 'ilike'? Else ensure case is stored correctly
					SsoRequestLog.log(current_user, @application, request, true, 'OK', {
							SAMLRequest: @saml_request,
							SAMLResponse: Base64.decode64(@saml_response)
					})

					Rails.logger.info Base64.decode64(@saml_response) if ENV['UMS_DEBUG_SAML'].to_b
					@message = t('devise.sessions.new.logging_in')
					@title = t('devise.sessions.new.login')
					cookies.delete(:SAMLRequest)
					render 'sso'
				else
					Rails.logger.info @saml_request.inspect if ENV['UMS_DEBUG_SAML'].to_b
					cookies[:SAMLRequest] = params[:SAMLRequest]
					redirect_to action: 'new'
				end
			end
		end
	end

	def saml_slo
		# see https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-single-sign-out-protocol-reference
		validate_saml_request
		#validate_saml_issuer

		# finally TODO refactor with destroy method for some commonality in handling SLO
		if user_signed_in?
			cookies.delete(:SAMLRequest)
			session.delete(:return_to)

			sign_out_extra_logic
		else
			redirect_to destroy_user_session_path
		end
	end

	def encode_slo_SAMLResponse(opts = {})
		now = Time.now.utc
		response_id = SecureRandom.uuid
		issuer_uri = opts[:issuer_uri] || (defined?(request) && request.url) || "http://example.com"

		xml = %[<samlp:LogoutResponse xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" ID="_#{response_id}" Version="2.0" IssueInstant="#{now.iso8601}" Destination="#{@saml_acs_url}" InResponseTo="#{@saml_request_id}">
<saml:Issuer>#{issuer_uri}</saml:Issuer>
<samlp:Status>
<samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success"/>
</samlp:Status>
</samlp:LogoutResponse>]

		Rails.logger.info xml if ENV['UMS_DEBUG_SAML'].to_b

		zstream  = Zlib::Deflate.new(Zlib::BEST_SPEED)

		output = Base64.encode64(zstream.deflate(xml))

		zstream.finish
		zstream.close

		output
	end

	def create
    #I don't think we need  params[:SAMLRequest] anymore
		if params[:SAMLRequest].present? ||  cookies[:SAMLRequest].present?
			validate_saml_request
		end
		user_params = params.require(:user).permit(:login, :password)

		@application = OauthApplication.find_by_saml_acs(@saml_acs_url) if @saml_acs_url.present?

		existing_user = User.includes(user_permissions: [ permission_type: [ :oauth_application ] ]).find_for_database_authentication(login: user_params[:login])

		# if there is no user, may need to sync their entitlements first (see maplesyrup/mdms entitlement rake tasks)
		# also could just be bad login
		super and return if existing_user.nil?

		password = user_params[:password]

		if @saml_request.present? && existing_user.valid_password?(password)
			# UMS is acting as SAML provider, SSO to consuming party, if valid
			if validate_saml_acs

				user_application = existing_user.application(@application.name)
				if user_application.nil? || user_application.is_blocked_due_to_status?
					flash[:alert] = I18n.t('devise.failure.inactive_user') and redirect_to new_user_session_path and return
				end

				cookies.delete(:SAMLRequest)
				existing_user.update_tracked_fields!(request)
				sign_in(existing_user, scope: :user)

        audience = @saml_request[/Issuer>(.+?)</, 1] #TODO, don't think we need to set this for OCConnect?
				@saml_response = encode_SAMLResponse(existing_user.email, issuer_uri: idp_landing_url, session_not_on_or_after: 2.hours.from_now ,  audience_uri:audience,attribute_provider:email_attribute_provider(existing_user.email))

				SsoRequestLog.log(existing_user, @application, request, true, 'OK', {
						SAMLRequest: @saml_request,
						SAMLResponse: Base64.decode64(@saml_response)
				})

				Rails.logger.info Base64.decode64(@saml_response) if ENV['UMS_DEBUG_SAML'].to_b
				@message = t('devise.sessions.new.logging_in')
				@title = t('devise.sessions.new.login')
				render 'sso'
			end
		else
			# not a SAML user, do whatever devise does
			super
		end
		update_devise_log
	end

	def new
		#cookies[:SAMLRequest] = params[:SAMLRequest] if !params[:SAMLRequest].blank?
    #I think dynamics call this directly, sending the SAMLRequest as a parameter
    #SessionStorage.set(session.id,:SAMLRequest,params[:SAMLRequest]) if !params[:SAMLRequest].blank?
		#@saml_request = SessionStorage.get(session.id,:SAMLRequest) || params[:SAMLRequest]
		#validate_saml_request(@saml_request)
		#SessionStorage.delete(session.id,:SAMLRequest)

		cookies[:ums_host] = {
				value: ENV['UMS_OC_OAUTH_HOST'],
				expires: 1.year.from_now,
				domain: Rails.env.development? ? 'localhost' : '.owenscorning.com'
		}

    @mailBoxUsers = User.where(shared_mailbox: true).pluck(:email).as_json

    if previously_signed_in_with_okta? || referring_application_requires_okta?
      redirect_to "/users/auth/okta" and return
    end

    if previously_signed_in_with_oktaabc?
      redirect_to "/users/auth/oktaabc" and return
    end

		@attempted_username = session[:attempted_username]
		session.delete(:attempted_username)

		super if validate_saml_acs
	end

	def destroy
		if params[:access_token]
			token = Doorkeeper::AccessToken.find_by(token: params[:access_token])
			if token
				token.revoke
			end

			# in this case we are coming from a site that knows to pass access_token to logout
			# find the log and deactivate it so during "sign_out_extra_logic" for SLO we don't try to sign out again
			SsoRequestLog.where(access_token: params[:access_token], is_active: true).update_all(is_active: false)
		end

		if user_signed_in?
			sign_out_extra_logic
		else
			super
		end
	end

  private

	def sign_out_extra_logic
		if user_signed_in?
			provider = current_user.provider
			user_id = current_user.id
			session_id = session.id

			signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))

			if signed_out
				set_flash_message :notice, :signed_out if is_flashing_format?
				log = Contractor::ImpersonationLog.where(impersonated_user_id: user_id, session_id: session_id, ended_at: nil).where.not(started_at: nil)
				begin
					log.update_all(ended_at: DateTime.now)
				rescue => e
					Rails.logger.error e.message
				end
			end

			# sign user out of other applications, if oauth session started for any
			slo_requests = SsoRequestLog.where(user_id: user_id, is_active: true).joins(:oauth_application).where.not(oauth_applications: { logout_url: nil })
			if slo_requests.exists?
				@slo_applications = OauthApplication.where(id: slo_requests.pluck('DISTINCT oauth_applications.id'))
				slo_requests.update_all(is_active: false)

				cookies.delete(:SAMLRequest)

				@logout_url = after_sign_out_path_for(resource_name)

				@message = t('devise.shared.signing_out')
				@title = t('devise.shared.logout')
				render 'sso'
			else
				return redirect_to ENV['UMS_LOGOUT_URL_ABCOKTA'] if provider == 'oktaabc'
				respond_to_on_destroy
			end
		end
	end

  REFERER_SIGN_IN_LAYOUTS = {
    "Customer Portal" => "customer_portal_sign_in"
  }

  # The ApplicationController#set_referer_application
  # before action sets @referer_application.
  def referrer_sign_in_layout
    REFERER_SIGN_IN_LAYOUTS.fetch(@referer_application, "application")
  end

  REFERER_VIEW_DIRECTORIES = {
    "Customer Portal" => :customer_portal
  }

  # The ApplicationController#set_referer_application
  # before action sets @referer_application.
  def referer_view_directory
    REFERER_VIEW_DIRECTORIES[@referer_application]
  end

  def set_referer_view_path
    prepend_view_path("app/views/#{referer_view_directory}")
  end

  def referring_application_requires_okta?
    @referer_application == "Okta-requiring Application"
  end

	def validate_saml_acs
		@application = OauthApplication.find_by_saml_acs(@saml_acs_url) if @saml_acs_url.present?
		if @saml_acs_url.present? && @application.nil?
			# this is an error, the SAML request came from unknown SP
			@saml_request = nil
			cookies.delete(:SAMLRequest)
			set_flash_message(:alert, :invalid_saml_sp)
			notify_airbrake(error_message: "Attempt to SAML with invalid SP #{@saml_acs_url}", cgi_data: ENV.to_hash)
			@saml_acs_url = nil
			@saml_issuer = nil
			redirect_to new_user_session_path
			false
		else
			true
		end
	end

	def email_attribute_provider(email)
		return %[<saml:AttributeStatement><saml:Attribute Name="mail"><saml:AttributeValue>#{email}</saml:AttributeValue></saml:Attribute></saml:AttributeStatement>]
	end

	def validate_saml_issuer
		@application = OauthApplication.find_by_saml_issuer(@saml_issuer) if @saml_issuer.present?
		if @saml_issuer.present? && @application.nil?
			# this is an error, the SAML request came from unknown SP
			@saml_request = nil
			cookies.delete(:SAMLRequest)
			set_flash_message(:alert, :invalid_saml_sp)
			notify_airbrake(error_message: "Attempt to SAML with invalid issuer #{@saml_issuer}", cgi_data: ENV.to_hash)
			@saml_acs_url = nil
			@saml_issuer = nil
			redirect_to new_user_session_path
			false
		else
			true
		end
	end
end
