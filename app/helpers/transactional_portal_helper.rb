module TransactionalPortalHelper
	TRANSACTIONAL_PORTAL_WSDL_URL = ENV['UMS_TRANSACTIONAL_SERVICE_WSDL']
	PORTAL_SERVICE_WSDL = ENV['UMS_PORTAL_SERVICE_WSDL']
	USER_SERVICE_WSDL = ENV['UMS_USER_SERVICE_WSDL']
	#WSDL_USERNAME = ENV['UMS_TRANSACTIONAL_SERVICE_USERNAME']
	#WSDL_PASSWORD = ENV['UMS_TRANSACTIONAL_SERVICE_PASSWORD']

	USER_ACCOUNT_CONTROL_HASH = {
			0 => nil,
			0x0001 => 'SCRIPT',
			0x0002 => 'ACCOUNTDISABLE',
			0x0008 => 'HOMEDIR_REQUIRED',
			0x0010 => 'LOCKOUT',
			0x0020 => 'PASSWD_NOTREQD',
			0x0040 => 'PASSWD_CANT_CHANGE',
			0x0080 => 'ENCRYPTED_TEXT_PWD_ALLOWED',
			0x0100 => 'TEMP_DUPLICATE_ACCOUNT',
			0x0200 => 'NORMAL_ACCOUNT',
			0x0800 => 'INTERDOMAIN_TRUST_ACCOUNT',
			0x1000 => 'WORKSTATION_TRUST_ACCOUNT',
			0x2000 => 'SERVER_TRUST_ACCOUNT',
			0x10000 => 'DONT_EXPIRE_PASSWORD',
			0x20000 => 'MNS_LOGON_ACCOUNT',
			0x40000 => 'SMARTCARD_REQUIRED',
			0x80000 => 'TRUSTED_FOR_DELEGATION',
			0x100000 => 'NOT_DELEGATED',
			0x200000 => 'USE_DES_KEY_ONLY',
			0x400000 => 'DONT_REQ_PREAUTH',
			0x800000 => 'PASSWORD_EXPIRED',
			0x1000000 => 'TRUSTED_TO_AUTH_FOR_DELEGATION',
			0x4000000 => 'PARTIAL_SECRETS_ACCOUNT'
	}

	def self.add_or_enable_ad_user(user_name, email, first_name, last_name, password)
		response = call_wrapper(user_client, :add_or_enable_user, user_name: user_name, first_name: first_name, last_name: last_name, email_address: email, password: password )
		success = response.try(:[], :error_status) == 'Success'
		raise "Could not add_or_enable_user: #{response.try(:[], :error_message)}" unless success
		success
	end
	def self.disable_ad_user(user_name)
		response = call_wrapper(user_client, :disable_user, user_name: user_name)
		success = response.try(:[], :error_status) == 'Success'
		raise "Could not disable_ad_user: #{response.try(:[], :error_message)}" unless success
		success
	end
	def self.get_ad_user(user_name)
		response = call_wrapper(user_client, :get_user_details_by_user_name, user_name: user_name)
		map_user_details_dto(response)
	end

	def self.get_ad_user_by_email(email)
		response = call_wrapper(user_client, :get_user_details_by_email_address, email_address: email)
		map_user_details_dto(response)
	end

	def self.get_ad_user_name_by_email(email)
		response = call_wrapper(transactional_client, :get_ad_user_name, email_address: email)
		response == 'User does not exists in AD Group' ? nil : response
	end

	def self.set_user_password(email, password)
		response = call_wrapper(transactional_client, :reset_user_password, email_address: email, password: password, reset_password: 0)
		success = response.try(:[], :error_status) == 'Success'
		raise "Could not update password: #{response.try(:[], :error_message)}" unless success
		success
	end

	# this is a good one to test portal service, it returns a savon::response so not suitable to use without more work
	def self.get_ad_user_email_by_user_id(user_id)
		response = call_wrapper(portal_client, :get_ad_user_email_by_user_id, user_id: user_id)
		response == 'User does not exists in Active Directory' ? nil : response
	end
	def self.get_user_invalid_login_attempts(user_id)
		response = call_wrapper(portal_client, :get_user_invalid_login_attempts, user_name: user_id)
		response
	end
	def self.reset_user_invalid_login_attempts(user_id)
		response = call_wrapper(portal_client, :reset_user_invalid_attempts, user_name: user_id)
		success = response.try(:[], :error_status) == 'Success'
		raise "Could not update invalid login attempts: #{response.try(:[], :error_message)}" unless success
		success
	end

private
	def self.call_wrapper(client, method, message)
		response = client.call(method, message: message)
		response = response.body.try(:[], "#{method}_response".to_sym).try(:[], "#{method}_result".to_sym)
		response
	end

	def self.map_user_details_dto(dto)
		dto.reject!{|k,v| k.to_s =~ /@xmlns:.*/}
		if dto.present?
			string = *(0..21).map{
					|b|
				USER_ACCOUNT_CONTROL_HASH[dto[:user_account_control].to_i & (1 << b)]
			}.reject{|v|v.blank?}.join('|')
			dto[:user_account_control_desc] = string[0]
		end
		dto.blank? ? nil : dto
	end

	def self.transactional_client
		TrackingSavon.client(wsdl: TRANSACTIONAL_PORTAL_WSDL_URL,
								 open_timeout:600,
								 read_timeout:600,
								 logger: Rails.logger,
								 log:true,
								 log_level: :debug,
								 pretty_print_xml:true,
								 element_form_default: :qualified,
								 namespace_identifier:'tem',
								 ssl_verify_mode: :none#,
								 #basic_auth: [WSDL_USERNAME, WSDL_PASSWORD]
		)
	end
	def self.portal_client
		TrackingSavon.client(wsdl: PORTAL_SERVICE_WSDL,
								 open_timeout:600,
								 read_timeout:600,
								 logger: Rails.logger,
								 log:true,
								 log_level: :debug,
								 pretty_print_xml:true,
								 element_form_default: :qualified,
								 namespace_identifier:'tem',
								 ssl_verify_mode: :none#,
		#basic_auth: [WSDL_USERNAME, WSDL_PASSWORD]
		)
	end
	def self.user_client
		TrackingSavon.client(wsdl: USER_SERVICE_WSDL,
								 open_timeout:600,
								 read_timeout:600,
								 logger: Rails.logger,
								 log:true,
								 log_level: :debug,
								 pretty_print_xml:true,
								 element_form_default: :qualified,
								 namespace_identifier:'tem',
								 ssl_verify_mode: :none#,
		#basic_auth: [WSDL_USERNAME, WSDL_PASSWORD]
		)
	end
end
