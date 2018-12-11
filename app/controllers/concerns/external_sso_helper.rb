module ExternalSsoHelper

	def estore
		if validate_signed_in
			if validate_sso_params
				if @to =~ ActionView::Helpers::AssetUrlHelper::URI_REGEXP
					querystring = "#{@to.include?('?') ? "&" : "?"}#{get_membership_querystring}"
					redirect_to "#{@to}#{querystring}"
				elsif is_estore_accessible?
					location_user = current_user.rce_virtual_adfs_users.find_by(location_guid: @location[:location].try(:downcase))
					if location_user
						add_sso_details({vusername: location_user.username, vemail: location_user.email})
						if sso_enable_check
							@estore_sso = true
							@adfs_logout_url = ENV['UMS_RCE_ADFS_LOGOUT_URL']
							@estore_logout_url = ENV['UMS_RCE_ESTORE_LOGOUT_URL']
							response = login_estore_rce_virtual_user(location_user, @to||'/OC/default.aspx?SuccessfulUrl=UserContentStart.aspx%3FcategoryCode%3Dproconnect_webstore')
							@sso_contents = response.html_safe
							@message = t('devise.sessions.new.logging_in')
							@title = t('devise.sessions.new.login')
							@test_url = ENV['UMS_RCE_ADFS_LOGIN_TEST_URL']
							render 'sso'
						end
					else
						fail_sso('no vuser found')
					end
				else
					fail_sso('no estore access')
				end
			end
		end
	end

	def bestroofcare
		if validate_signed_in
			if validate_sso_params
				if sso_enable_check
					redirect_to SmartURI.join(@application.application_uri, "/authenticate?info=#{encrypt_info_for_bestroofcare}")
				end
			end
		end
	end

	def cards
		if validate_signed_in
			if validate_sso_params
				@maritz_sso_data = encrypt_info_for_maritz
				if sso_enable_check
					@message = t('devise.sessions.new.logging_in')
					@title = t('devise.sessions.new.login')
					render 'sso'
				end
			end
		end
	end

	def warranty
		if validate_signed_in
			if current_user.get_permission_value('CONTRACTOR_PORTAL', 'ACCESS_WARRANTY').to_b || current_user.get_permission_value('CONTRACTOR_PORTAL', 'ACCESS_WARRANTIES').to_b
				if validate_sso_params
					if sso_enable_check
						redirect_to SmartURI.join(@application.application_uri, "/authenticateUser?info=#{CGI.escape encrypt_info_for_warranty}")
					end
				end
			else
				fail_sso('no warranty permission')
			end
		end
	end

	def learning
		if validate_sso_params
			if sso_enable_check
				redirect_to @application.application_uri
			end
		end
	end

	def lms
		if validate_signed_in
			if validate_sso_params
				if sso_enable_check
					oc_com_app = OauthApplication.find_by_name('OC_COM')
					path = "/connect/contractors/#{@location.try(:membership_number)}/lead-assignments"
					redirect_to File.join(oc_com_app.application_uri, path)
				end
			end
		end
	end

	private
	def fail_sso(message)
		unless user_signed_in?
			session[:return_to] = self.send(:"#{params[:action]}_sso_path", params[:location])
		end
		if current_user
			SsoRequestLog.log(current_user, @application, request, false, message, @sso_details)
		end
		redirect_to new_user_session_path
	end
	def validate_signed_in
		if user_signed_in?
			true
		else
			fail_sso('not signed in')
			false
		end
	end
	def add_sso_details(hash)
		@sso_details = (@sso_details||{}).merge(hash)
	end
	def sso_enable_check
		add_sso_details({email: current_user.try(:email), location: @location.try(:location), membership_number: @location.try(:membership_number)})

		application_proper_name = @application.try(:proper_name)
		env = ENV["UMS_SSO_#{@application.try(:name).to_s.upcase}_DISABLE"].to_b
		if env
			@title = "#{application_proper_name} SSO"
			@message = "If SSO to #{application_proper_name} were enabled you would succesfully be taken to #{@to.present? ? "#{@to} within #{application_proper_name}." : "the #{application_proper_name} landing page."}"
			render 'sso_placeholder'
			false
		else
			maintenance_message = @application.active_maintenance_messages.first
			if maintenance_message.nil?
				SsoRequestLog.log(current_user, @application, request, true, 'OK', @sso_details)
				true
			else
				@title = application_proper_name
				@message = maintenance_message.message
				@start_date = maintenance_message.start_date_utc
				@end_date = maintenance_message.end_date_utc
				SsoRequestLog.log(current_user, @application, request, false, 'Blocked for maintenance message', @sso_details)
				render 'sso_maintenance'
				false
			end
		end
	end

	def is_estore_accessible?
		@estore_profile = current_user.estore_profiles.where(location: @location.location).first
		@estore_profile.present? && @estore_profile.is_active
	end

	def encrypt_info_for_maritz
		builder = Nokogiri::XML::Builder.new do |xml|
			xml.userToken {
				xml.username [(sprintf '%09d', current_user.id), (sprintf '%09d', @location.membership_number)].join('')
				xml.timestamp (Time.now.to_f * 1000).to_i
			}
		end
		userToken = builder.doc.root.to_xml
		add_sso_details({userToken: "<pre lang=\"xml\">#{CGI::escapeHTML userToken}</pre>".html_safe})
		encryptedUserToken = EncryptionHelper.encrypt_aes256_cbc_pkcs5_base64(userToken.encode('ASCII'), ENV['RCE_MARITZ_USER_TOKEN_ENCRYPTION_KEY'])
		add_sso_details({encryptedUserToken: Base64.encode64(Base64.strict_decode64(encryptedUserToken)).gsub("\n", "<br>").html_safe})
		encryptedUserToken
	end

	def encrypt_info_for_warranty
		Base64.strict_encode64(EncryptionHelper.encrypt_3des_ecb_md5("MemberID=#{@location.membership_number},Timestamp=#{Time.now.utc.strftime('%m-%d-%Y %H:%M:%S')},SecurityToken=#{ENV['RCE_WARRANTY_SECURITY_TOKEN']}", ENV['RCE_WARRANTY_ENCRYPT_KEY']))
	end

	def encrypt_info_for_bestroofcare
		Base64.strict_encode64(EncryptionHelper.encrypt_3des_cbc_sha1("MemberID=#{@location.membership_number},DateTimeStamp=#{Time.now.utc.strftime('%m-%d-%Y %H:%M:%S')},SecurityToken=#{ENV['RCE_BESTROOFCARE_SECURITY_TOKEN']}", ENV['RCE_BESTROOFCARE_ENCRYPT_KEY']))
	end

	def validate_sso_params
		@application = OauthApplication.where(sso_token: params[:action]).first
		@to = get_to_path

		if user_signed_in?
			level = current_user.get_permission_value('CONTRACTOR_PORTAL', 'LEVEL').try(:downcase)
			account = current_user.get_permission_value('CONTRACTOR_PORTAL', 'ACCOUNT').try(:downcase)
			locations = (current_user.get_permission_value('CONTRACTOR_PORTAL', 'LOCATION').try(:downcase)||'').split(',').map(&:strip)
			given_location = params[:location].try(:downcase)
			@location = Contractor::MemberProfile.for_location(given_location).first
			if @location.present? && ((level == 'global' && @location.account.try(:downcase) == account) || locations.include?(given_location))
				true
			else
				fail_sso("no access to given location: #{given_location}")
				false
			end
		else
			fail_sso('not signed in')
			false
		end
	end

	def get_to_path
		to = (@application.present? && params[:to].present?) ? SsoRedirect.where(oauth_application_id: @application.id).find_by_token(params[:to]) : nil
		to.try(:path)
	end

	def login_estore_rce_virtual_user(vuser, ru=nil)
		unlock_error = nil
		begin
			TransactionalPortalHelper.reset_user_invalid_login_attempts(vuser.username)
		rescue => e
			unlock_error = e
		end

		url = get_rce_estore_signon_url(ru)
		agent = Mechanize.new { |agent|
			agent.user_agent = request.user_agent
			agent.log = Logger.new(STDOUT)
		}

		agent.agent.http.verify_mode = OpenSSL::SSL::VERIFY_NONE if ENV['UMS_ADFS_IGNORE_CERTS'].to_b

		page = agent.get(url)

		f = page.form('aspnetForm')
		f.field_with(:name => /UsernameTextBox$/).value = vuser.username
		f.field_with(:name => /PasswordTextBox$/).value = vuser.password
		page2 = agent.submit(f, f.buttons.first)

		# after login user gets a hidden form auto-posted by JS
		f = page2.form('hiddenform')

		# save off this body with hidden form to serve later
		response = page2.body
		if f.nil?
			if /Your account is locked/ =~ response
				if unlock_error.present?
					raise unlock_error
				else
					raise 'reported adfs account is locked, but we just called to unlock it?'
				end
			else
				raise 'hiddenform not found'
			end
		end

		#			page2 = agent.submit(f, f.buttons.first)

		#			# check for another hidden form, which happens sometimes
		#			f = page2.form('hiddenform')
		#			if f.present?
		#				response = page2.body
		#			end

		response = response.gsub(/"#{CGI.unescape(ENV['UMS_RCE_ADFS_WTREALM'])}?"/, "\"#{ENV['UMS_RCE_ADFS_WIFHANDLER']}\"")
		response
	end

	def get_rce_estore_signon_url(ru=nil)
		"#{ENV['UMS_ADFS_LOGIN_URL']}&wtrealm=#{ENV['UMS_RCE_ADFS_WTREALM']}&wctx=#{format_wctx(ru)}"
	end
	def format_wctx(ru=nil)
		(ENV['UMS_RCE_ESTORE_ADFS_WCTX']||'').gsub(/\#{ru}/, ru ? CGI.escape("ru=#{CGI.escape(ru)}") : '')
	end
	def get_membership_querystring
		if @location.present?
			legacy_params = {
					membership: @location.membership_number,
					location: @location.location
			}
			legacy_params.to_query
		end
	end
end
