class SsoRedirect < ActiveRecord::Base
	belongs_to :application, foreign_key: :oauth_application_id, class_name: 'OauthApplication'
	validates :application, presence: true
	validates :token, presence: true
	validates :path, presence: true

	def custom_label_method
		"#{application.try(:name)} - #{token}"
	end

	rails_admin do
		parent OauthApplication
		label 'SSO Redirect'
		object_label_method do
			:custom_label_method
		end
	end
end