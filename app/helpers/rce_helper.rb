module RceHelper
	RCE_BASE_URL = ENV['RCE_BASE_URL']
	RCE_PROVISION_USER_MESSAGE = ENV['RCE_PROVISION_USER_MESSAGE']
	RCE_USER_AUTH_STATUS_MESSAGE = ENV['RCE_USER_AUTH_STATUS_MESSAGE']
	RCE_PASSCODE = ENV['RCE_PASSCODE']
	RCE_ACCESS_TOKEN = ENV['RCE_ACCESS_TOKEN']

	MDMS_URL = ENV['MDMS_URL']

	def self.is?(thing)
		is = false
		is = true if thing.kind_of?(String) && thing == 'CONTRACTOR_PORTAL'
		is = true if thing.kind_of?(OauthApplication) && thing.name == 'CONTRACTOR_PORTAL'
		is = true if thing.kind_of?(UserApplication) && thing.oauth_application.name == 'CONTRACTOR_PORTAL'
		#others?

		if is && block_given?
			yield
		end
		is
	end

	class Scribe
		include TrackingHttparty
		default_timeout 180
		base_uri RCE_BASE_URL
		default_params accesstoken: RCE_ACCESS_TOKEN
		headers "Content-Type" => "application/json"
		debug_output $stdout

		def provision_user(body = {})
			post_message(RCE_PROVISION_USER_MESSAGE, body)
		end
		def update_user_auth_status(application_id)
			application = UserApplication.where(id: application_id).first
			return if application.nil?

			data = {
					contactGUID: application.external_id,
					authStatus: UserSerializer.map_invitation_status_to_auth_status(application.oauth_application, application),
					authLoginCount: application.user.sign_in_count
			}
			Rails.logger.info("Sending #{data[:authStatus]} logins(#{data[:authLoginCount]}) to scribe for user '#{application.user.username}', ext id: '#{data[:contactGUID]}'")

			post_message(RCE_USER_AUTH_STATUS_MESSAGE, data)
		end
		private
		def post_message(url, body, timeout = nil)
			options = {
					body: JSON.dump(body.merge({passcode: RCE_PASSCODE})),
			}
			options = options.merge(timeout: timeout) if timeout.present?

			response = self.class.post(url, options)
			check_and_raise_error response

			if response.success?
				# this is not actually a guarantee, the data might have a failure
				data = response['data'].first
				data.except('returnCode', 'returnMessage').deep_transform_keys! {|k| k.to_s.underscore.to_sym }
			end
		end
		def check_and_raise_error(response)
			raise_appropriate_error(response.code, response.message) unless response.success?
			if response.success?
				# this is not actually a guarantee, the data might have a failure
				data = response['data'].first
				if data['returnCode'] && data['returnCode'] != '200'
					raise_appropriate_error(data['returnCode'], data['returnMessage'])
				end
			end
		end
		def raise_appropriate_error(code, message)
			code = code.to_s
			message = message.to_s
			raise Timeout::Error if %w(503 504).include?(code)
			raise "#{code}: #{message}"
		end
	end

	class Mdms
		include TrackingHttparty
		default_timeout 180
		base_uri MDMS_URL
		headers "Content-Type" => "application/json"

		def headers
			{ 'Authorization' => "Bearer #{Owenscorning::WebCommon::UmsLogin.get_application_token}" }
		end

		def update_user(user)
			Rails.logger.info("Sending update to mdms for user '#{user.id}'")

			body = JSON.dump({
													 user: JSON.parse(UserSerializer.new(user, root: false, scope: { root: false, snakecase: true, current_application: OauthApplication.find_by_name('CONTRACTOR_PORTAL') }, scope_name: :serialization_context).to_json)
											 })

			response = self.class.post('/api/v1/contractor/users',
					 headers: headers,
					 body: body)
			raise "#{response.code}: #{response.message}" unless response.success?
		end

		def requeue_pi_file
			Rails.logger.info("Sending request to mdms to launch PI file generation")
			response = self.class.get('/api/v1/contractor/check_disbursements/requeue',
																 headers: headers)
			raise "#{response.code}: #{response.message}" unless response.success?
		end

		def resend_to_pqs(id)
			Rails.logger.info("Sending request to mdms to re-send to PQS")
			response = self.class.get("/api/v1/contractor/member_profiles/requeue_pqs/#{id}",
																headers: headers)
			raise "#{response.code}: #{response.message}" unless response.success?
		end

		def requeue_redemption(id)
			Rails.logger.info("Sending request to mdms to re-send redemption")
			response = self.class.get("/api/v1/contractor/member_profiles/requeue_redemption/#{id}",
																headers: headers)
			raise "#{response.code}: #{response.message}" unless response.success?
		end

		def requeue_member_profile_sync(id)
			Rails.logger.info("Sending request to mdms to re-sync member profile")
			response = self.class.get("/api/v1/contractor/member_profiles/#{id}/requeue",
																headers: headers)
			raise "#{response.code}: #{response.message}" unless response.success?
		end
	end

	def self.update_user_auth_status(user)
		application = user.application('CONTRACTOR_PORTAL')
		if application.present? && application.external_id.present?
			Scribe.new.delay.update_user_auth_status(application.id)

			Mdms.new.delay.update_user(user)
		end
	end

	def self.update_mdms_on_user_edit(user)
		Mdms.new.delay.update_user(user)
	end

	def self.requeue_pi_file
		Mdms.new.requeue_pi_file
	end

	def self.resend_to_pqs(id)
		Mdms.new.resend_to_pqs(id)
	end

	def self.requeue_redemption(id)
		Mdms.new.requeue_redemption(id)
	end

	def self.requeue_member_profile_sync(id)
		Mdms.new.requeue_member_profile_sync(id)
	end

	def self.provision_user(user)
		application = user.application('CONTRACTOR_PORTAL')
		if application.present? && application.external_id.present?
			Scribe.new.provision_user(contactGUID: application.external_id)
		end
	end
end
# ocbmcontractorportaldev.microsoftcrmportals.com
# owenscorning-bmg-uat.microsoftcrmportals.com
# owenscorning-bmg-prd.microsoftcrmportals.com