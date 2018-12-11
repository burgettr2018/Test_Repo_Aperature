class ApiOwenscorningCom
	include HTTParty
	base_uri 'https://api.owenscorning.com/ProConnectLMSService.svc'
	debug_output $stdout

	BNR_API_VENDOR_ID = ENV['BNR_API_VENDOR_ID']
	BNR_API_ENCRYPT_KEY = ENV['BNR_API_ENCRYPT_KEY']
	BNR_API_APP_TOKEN = ENV['BNR_API_APP_TOKEN']

	def self.get_lead_details_by_id(lead_id, contractor_email_address)
		get_data('/GetLeadDetailsByID', leadID: lead_id, contractorEmailAddress: contractor_email_address)
	end

	def self.get_roofing_product_ids_by_zipcode(zipcode)
		get_data('/GetRoofingProductIDsForZipCode', ZipCode: zipcode)
	end

	def self.auth_pro_connect_cont_by_user_name_pass(user_name, pass)
		post_data('/AuthProConnectContByUserNamePass', password: pass, userDeviceId: 'sadsad', userName: user_name)
	end

	def self.test_api_gateway(mode, user_name, pass, expect_pass = true)
		case mode.downcase
			when 'api'
				base_uri 'https://api.owenscorning.com'
				path = '/ProConnectLMSService.svc/AuthProConnectContByUserNamePass'
			when 'api-proxy'
				base_uri 'https://api-proxy.owenscorning.com'
				path = '/ProConnectLMSService.svc/AuthProConnectContByUserNamePass'
			when 'api-origin'
				base_uri 'https://api-origin.owenscorning.com'
				path = '/ProConnectLMSService.svc/AuthProConnectContByUserNamePass'
			when 'prodapig'
				base_uri 'https://r3lke0xb7g.execute-api.us-east-1.amazonaws.com/prod'
				path = '/ProConnectLMSService.svc/AuthProConnectContByUserNamePass'
			when 'devapig'
				base_uri 'https://hug1oluug1.execute-api.us-east-1.amazonaws.com/devel'
				path = '/ProConnectLMSService.svc/AuthProConnectContByUserNamePass'
			when 'mdms-devel'
				base_uri 'https://mdms-devel.owenscorning.com'
				path = '/api/v1/contractor/deqsnapshot-user-validation'
			when 'mdms-prod'
				base_uri 'https://mdms.owenscorning.com'
				path = '/api/v1/contractor/deqsnapshot-user-validation'
			when 'localhost'
				base_uri 'http://localhost:3001'
				path = '/api/v1/contractor/deqsnapshot-user-validation'
			when 'slsoffline'
				base_uri 'http://localhost:3000'
				path = '/ProConnectLMSService.svc/AuthProConnectContByUserNamePass'
			else
				raise 'check mode parameter'
		end
		response = post_data(path, password: pass, userDeviceId: 'sadsad', userName: user_name)
		error = false
		if response.success?
			if !expect_pass
				puts 'ERROR - expected to fail'
				error = true
			else
				if (response.headers['set-cookie']||'') =~ /UserToken=[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12};/
					puts 'OK - set-cookie has UserToken'
				else
					puts 'ERROR - expected set-cookie header with UserToken'
					error = true
				end
				parsed = JSON.parse(response.body, {symbolize_names: true})
				required_keys = %i(First_name last_name member_id company_name Zip_code email)
				required_present_keys = required_keys + %i(home_phone mobile_phone)
				if (required_present_keys-parsed.keys).any?
					puts "ERROR - expected keys not in response: #{(required_present_keys-parsed.keys).join(', ')}"
					error = true
				else
					puts 'OK - all expected keys in response'
				end
				if required_keys.select{|k| parsed[k].blank?}.any?
					puts "ERROR - expected keys blank in response: #{required_keys.select{|k| parsed[k].blank?}.join(', ')}"
					error = true
				else
					puts 'OK - all keys expected to be non-blank are present in response'
				end
			end
		else
			if !expect_pass
				if response.code == 401
					puts 'OK - expected to fail'
				else
					puts 'ERROR - expected 401 error'
					error = true
				end
			else
				puts 'ERROR - expected to pass'
				error = true
			end
		end
		response if error
	end

	private
	def self.get_cookie_header
		{ 'Cookie' => "UserToken=\"#{'0D5DD50B-970D-4935-B901-8B7C673F2770'}\"; AppToken=\"#{get_app_token}\"; VendorID=#{BNR_API_VENDOR_ID}" }
	end
	def self.get_data(url, options)
		get(url, query: options, headers: get_cookie_header)
	end
	def self.post_data(url, body)
		headers = get_cookie_header.merge({ 'Content-Type' => 'application/json' })
		options = {
				:body => body.try(:to_json)||'',
				headers: headers
		}
		post(url, options)
	end
	def self.get_app_token
		encrypted_app_token = EncryptionHelper.encrypt_3des_cbc_sha1_base64(BNR_API_APP_TOKEN, BNR_API_ENCRYPT_KEY)
		EncryptionHelper.encrypt_3des_cbc_sha1_base64("#{encrypted_app_token}~#{Time.now.utc.strftime('%Y-%m-%d %H:%M:%S.%L')}", BNR_API_ENCRYPT_KEY)
	end
end
