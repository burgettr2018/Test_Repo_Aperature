class PasswordsController < Devise::PasswordsController
	skip_before_action :assert_reset_token_passed, only: :edit
	skip_before_action :require_no_authentication, only: :edit

	prepend_before_filter :require_no_authentication, unless: :signed_in?
	append_before_filter :assert_reset_token_passed, only: :edit, unless: :signed_in?


	def create
		user = User.find_or_initialize_with_errors(Devise.reset_password_keys, resource_params, :not_found)
		if user.present? && !user.new_record? && @referer_application.present?
			user.update_columns(last_application_context: @referer_application)
		end
		super
	end

	def edit
		if signed_in?
			self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
			set_minimum_password_length
		else
			super
		end
	end

	def update
		if signed_in?
			self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
			test_user = User.new(update_password_params.except(:current_password))
			test_user.check_password_complexity
			test_user.password_match?
			if test_user.errors.empty? && resource.update_with_password(update_password_params)
				# Sign in the user bypassing validation in case password changed
				bypass_sign_in resource
				redirect_to after_update_path_for(resource)
			else
				test_user.errors.keys.each do |k|
					resource.errors[k].concat test_user.errors[k]
				end
				render 'edit'
			end
		else
			# this is a reset password for unsigned in user, devise can handle
			super
			# but if configured to sign in after reset, we need to clear any pending invitation
			if Devise.sign_in_after_reset_password && resource.present? && resource.errors.empty?
				resource.user_applications.each do |a|
					unless a.invitation_token.nil?
						a.update_columns(invitation_token: nil)
					end
				end
			end
		end
		update_devise_log
	end

	private
	def update_password_params
		params.require(:user).permit(:password, :password_confirmation, :current_password)
	end
end
