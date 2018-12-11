class DeviseMailer < Devise::Mailer
	helper :application # gives access to all helpers defined within `application_helper`.
	include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`

	def mailer_sender(mapping, sender = :from)
		if @application.try(:name) == 'CONTRACTOR_PORTAL'
			return 'Owens Corning Roofing <prodesk@owenscorning.com>'
		end
		super
	end

	def devise_mail(record, action, opts={})
		initialize_from_record(record)
		mail headers_for(action, opts) do |format|
			format.mjml { render 'generic' }
			format.text
		end
	end

	def confirmation_instructions(record, token, opts={})
		get_application(record)

		@strong_header_content = "#{t('devise.shared.welcome')} #{record.email}!"
		@body_content = []
		@body_content << {type: 'copy_block', text: t('devise.mailers.confirmation_instructions.confirm_account_instructions')}
		@body_content << {
				type: 'cta',
				url: confirmation_url(record, confirmation_token: token),
				text: t('devise.mailers.confirmation_instructions.confirm_my_account')
		}

		@body_content << {
				type: 'copy_block',
				text: t("user_mailer.shared.html_contact_prodesk", @i18n_params)
		} if @application.try(:name) == 'CONTRACTOR_PORTAL'

		super
	end

	def reset_password_instructions(record, token, opts={})
		get_application(record)

		@strong_header_content = "#{t('devise.shared.hello')} #{record.email}!"
		@body_content = []

		if record.is_database_provider
			@body_content << {type: 'copy_block', text: t('devise.mailers.reset_password_instructions.requested_password_change')}
			@body_content << {
					type: 'cta',
					url: edit_password_url(record, reset_password_token: token),
					text: t('devise.mailers.reset_password_instructions.change_my_password')
			}
			@body_content << {type: 'copy_block', text: t('devise.mailers.reset_password_instructions.if_not_requesting')}
			@body_content << {type: 'copy_block', text: t('devise.mailers.reset_password_instructions.create_new_password_instructions')}
		else
			provider_name = OmniAuth::Utils.camelize(@resource.provider)
			provider_name = SamlIdentityProvider.where(token: @resource.provider).first.try(:name) || provider_name
			@body_content << {type: 'copy_block', text: t('devise.mailers.reset_password_instructions.requested_password_change_with_provider', provider: provider_name)}
			@body_content << {type: 'copy_block', text: t('devise.mailers.reset_password_instructions.check_with_support_provider', provider: provider_name)}
			@body_content << {type: 'copy_block', text: t('devise.mailers.reset_password_instructions.if_not_requesting')}
		end

		@body_content << {
				type: 'copy_block',
				text: t("user_mailer.shared.html_contact_prodesk", @i18n_params)
		} if @application.try(:name) == 'CONTRACTOR_PORTAL'

		super
	end

	def unlock_instructions(record, token, opts={})
		get_application(record)

		@strong_header_content = "#{t('devise.shared.hello')} #{record.email}!"
		@body_content = []
		@body_content << {type: 'copy_block', text: t('devise.mailers.unlock_instructions.account_locked')}
		@body_content << {type: 'copy_block', text: t('devise.mailers.unlock_instructions.html_unlock_instructions')}
		@body_content << {
				type: 'cta',
				url: unlock_url(record, unlock_token: token),
				text: t('devise.mailers.unlock_instructions.unlock_my_account')
		}

		@body_content << {
				type: 'copy_block',
				text: t("user_mailer.shared.html_contact_prodesk", @i18n_params)
		} if @application.try(:name) == 'CONTRACTOR_PORTAL'

		super
	end

	def password_change(record, opts={})
		get_application(record)

		@strong_header_content = "#{t('devise.shared.hello')} #{record.email}!"
		@body_content = []
		@body_content << {type: 'copy_block', text: t('devise.mailers.password_change.password_change_notification')}

		@body_content << {
				type: 'copy_block',
				text: t("user_mailer.shared.html_contact_prodesk", @i18n_params)
		} if @application.try(:name) == 'CONTRACTOR_PORTAL'

		super
	end

	private
	def get_application(record)
		@application = OauthApplication.find_by_name(record.last_application_context)
		@app = @application.try(:name)
	end
end
