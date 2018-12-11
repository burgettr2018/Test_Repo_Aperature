# Preview all emails at http://localhost:3000/rails/mailers/devise_mailer
class DeviseMailerPreview < ActionMailer::Preview
	def reset_password_instructions
		user = User.first.dup
		user.last_application_context = @application.try(:name)
		DeviseMailer.reset_password_instructions(user, "faketoken", {})
	end

	def unlock_instructions
		user = User.first.dup
		user.last_application_context = @application.try(:name)
		DeviseMailer.unlock_instructions(user, "faketoken", {})
	end

	def password_change
		user = User.first.dup
		user.last_application_context = @application.try(:name)
		DeviseMailer.password_change(user, {})
	end

	def params=(params)
		@application = params[:application].present? ? OauthApplication.find_by_name(params[:application]) : nil
	end
end
