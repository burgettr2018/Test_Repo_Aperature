class UserEmailValidationFailure < ActiveRecord::Base
	belongs_to :oauth_application

	def self.log(post_data, application=nil)
		application = OauthApplication.find_by_name('UMS') if application.nil?
		r = find_or_create_by!(email: post_data[:email], oauth_application_id: application.id) do |r|
			r.start_date_utc = DateTime.now.utc
		end
		r.update(end_date_utc: DateTime.now.utc, last_post_body: post_data.to_h)
	end

	rails_admin do
		parent User
		list do
			include_fields :id, :start_date_utc, :end_date_utc, :email, :oauth_application
		end
	end
end