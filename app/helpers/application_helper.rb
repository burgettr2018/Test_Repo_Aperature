module ApplicationHelper
	include ApiParametersHelper

	def format_expiry_message(user_application_record)
		response = I18n.t('devise.failure.invitation_expired')
		#TODO re-invite url
		#response += "<a href=\"#{'#'}\">#{I18n.t('devise.failure.request_new_invitation')}</a>" if user_application_record.invited_by.present?
		response
	end

	def feature?(name)
		Feature.flipper[name].enabled? Feature::User.from_session(session)
	end

	def digital_data(data={})
		# create instance storage for dataLayer properties
		@analytics_data_layer ||= {
				global: {
						pageName: (%w(oc ums) + request.path.split('/').select(&:present?)).join(' | '),
						siteName: 'oc user management',
						pageURL: request.path,
				}
		}

		@analytics_data_layer.deep_merge!(data)

		content_for(
				:analytics_data_layer,
				content_tag('script', %(digitalData = #{@analytics_data_layer.to_json};).html_safe),
				:flush => true # This flag REPLACES all content_for the given symbol
		)
	end
end
