class SsoRequestLog < ActiveRecord::Base
	belongs_to :user
	belongs_to :oauth_application
	rails_admin do
		parent User
		label 'SSO Request Log'
		list do
			include_fields :user, :oauth_application, :time, :ip, :is_active
		end
	end

	def self.log(user, application, request, is_success, message, details = {})
		SsoRequestLog.create(
				user_id: user.try(:id),
				time: Time.now.utc,
				oauth_application_id: application.try(:id),
				params: details.presence.try(:except, :access_token),
				ip: request.remote_ip,
				trace_id: nil,  #TODO trace_id
				is_active: true,
				is_success: is_success,
				message: message,
				access_token: details.try(:[], :access_token)
		)
	end
end
