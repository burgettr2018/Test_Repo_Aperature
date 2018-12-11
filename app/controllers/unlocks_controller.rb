class UnlocksController < Devise::UnlocksController
	def create
		user = User.find_or_initialize_with_errors(Devise.unlock_keys, resource_params, :not_found)
		if user.present? && !user.new_record? && @referer_application.present?
			user.update_columns(last_application_context: @referer_application)
		end
		super
	end
end