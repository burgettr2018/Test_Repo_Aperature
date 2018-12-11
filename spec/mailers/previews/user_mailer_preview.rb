# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
	def params=(params)
		@params = params
	end

	def application_welcome
		user = User.first
		application = 'OC_COM'
		password = '##password##'
		request = nil
		UserMailer.application_welcome(user, password, application, request)
	end
	def invitation
		user_application = get_user_application('invited')
		mail = UserMailer.invitation(user_application.id, Devise.friendly_token(20), user_application.invitation_expires_in)
		#user_application.delete
		mail
	end
	def invitation_reminder
		user_application = get_user_application('invited')
		mail = UserMailer.invitation_reminder(user_application.id, Devise.friendly_token(20), user_application.invitation_expires_in/2)
		#user_application.delete
		mail
	end
	def invitation_expired_invitee
		user_application = get_user_application('expired')
		mail = UserMailer.invitation_expired_invitee(user_application.id, Devise.friendly_token(20))
		#user_application.delete
		mail
	end
	def invitation_expired_inviter
		user_application = get_user_application('expired')
		mail = UserMailer.invitation_expired_inviter(user_application.id, Devise.friendly_token(20))
		#user_application.delete
		mail
	end
	def invitation_rerequested_inviter
		user_application = get_user_application('expired')
		mail = UserMailer.invitation_rerequested_inviter(user_application.id)
		#user_application.delete
		mail
	end

	private
	def get_user_application(status)
		user = User.last
		application = OauthApplication.find_by_name(@params[:application]) || OauthApplication.find_by_name('OC_COM')
		now = DateTime.now
		inviter = User.first if @params[:invited_by].present?
		ua = UserApplication.find_or_initialize_by(
				user_id: user.id,
				oauth_application_id: application.id
		)
		ua.invitation_expires_in = application.invitation_expiry_days.to_i.days
		ua.first_invitation_sent_at = now
		ua.current_invitation_sent_at = now
		ua.invitation_token = Devise.friendly_token(20)
		ua.invited_by_id = inviter.try(:id)
		ua.invitation_status = status
		ua.save(validate: false)
		ua
	end
end
