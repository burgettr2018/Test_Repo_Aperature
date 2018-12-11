class ExternalApiRequestLog < ActiveRecord::Base
	before_create :set_calculated_attributes
	def set_calculated_attributes
		self.oauth_application_id = OauthApplication.find_by_name('UMS').id
	end

	belongs_to :oauth_application

	rails_admin do
		navigation_label 'APIs'
		label 'Outgoing API Request Log'
		list do
			include_fields :status, :method, :oauth_application, :url, :time
		end
	end
end
