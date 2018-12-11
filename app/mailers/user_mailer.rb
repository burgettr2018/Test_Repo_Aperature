class UserMailer < ApplicationMailer
  include ActionView::Helpers::DateHelper

  def application_welcome(user, password, application)
    @user = user
    @password = password

    @application = OauthApplication.find_by_name(application)
    @app_name = @application.try(:proper_name)
    @app_url = @application.try(:application_uri)

    mail(to: user.email, subject: "#{t('devise.shared.welcome_to')} #{@app_name}")
  rescue => e
    logger.error e
  end

  class DummyMailer
    def deliver_now
      # do nothing
    end
    def deliver
      # do nothing
    end
  end

  def invitation(user_application_id, raw_token, expiry)
    user_application = UserApplication.where(id: user_application_id).first
    return if user_application.nil?

    @invitation = user_application

    send_launch_invitation = true

    if %w(complete inactive).include?(@invitation.invitation_status)
      #don't send for either of these status,
      #but invited/re-invited/expired ok
      DummyMailer.new
    else
      @user = @invitation.user
      I18n.locale = @user.preferred_language.presence || I18n.default_locale
      @application = @invitation.oauth_application
      @app_name = @application.try(:name) == 'CUSTOMER_PORTAL' ? t('user_mailer.app_name.customer_portal') : @application.try(:proper_name)
      @app_url = @application.try(:real_application_uri)
      @accept_url = accept_invitation_url(token: raw_token)
      @resubmit_invitee_url = resubmit_invitee_url(token: raw_token)
      @resubmit_inviter_url = resubmit_inviter_url(token: raw_token)
      @expiry = expiry

      from = default_params[:from]
      from = 'Owens Corning Roofing <prodesk@owenscorning.com>' if @application.try(:name) == 'CONTRACTOR_PORTAL'

      @i18n_params = {
          app_name: @app_name,
          name: @invitation.invited_by_name,
          from_name: @invitation.invited_by_from_name,
          from_email: @invitation.invited_by_email,
          period: @expiry.nil? ? nil : distance_of_time_in_words(@expiry),
          to_name: @user.name,
          to_email: @user.email
      }

      subject = t("user_mailer.#{action_name}.subject", @i18n_params)
      to = @user.email
      to = @invitation.invited_by_email if action_name == 'invitation_rerequested_inviter' || action_name == 'invitation_expired_inviter'

      #RCE-496 - special invite email continues after launch
      if @application.try(:name) == 'CONTRACTOR_PORTAL' && action_name == 'invitation' && send_launch_invitation
        subject = 'Add This to Your Toolbox Today'
        mail(to: to, from: from, subject: subject) do |format|
          format.html { render 'launch_invitation' }
        end
      elsif @application.try(:name) == 'CUSTOMER_PORTAL' && action_name == 'invitation'
        assignee_email = user_application.assigned_to.try(:email)
        @i18n_params.merge!({assignee_email: assignee_email})
        @body_content = [
          {
            type: 'copy_block',
            text: t("user_mailer.#{action_name}.customer_portal.html_accept_instructions", @i18n_params)
          },
          {
            type: 'cta',
            url: @accept_url,
            text: t("user_mailer.#{action_name}.customer_portal.access_portal")
          },
          {
            type: 'copy_block',
            text: t("user_mailer.#{action_name}.customer_portal.portal_link_prompt")
          },
          {
            type: 'text_link',
            url: @app_url,
            text: @app_url
          },
          {
            type: 'copy_block',
            text: t("user_mailer.#{action_name}.customer_portal.thank_you_instructions", @i18n_params)
          }
        ]

        user = user_application.user
        to = user.email
        @app = @application.name
        @i18n_params.merge!({name: "#{user.first_name} #{user.last_name}"})
        @header_content = t("user_mailer.#{action_name}.customer_portal.salutation", @i18n_params)
        @signoff = t("user_mailer.#{action_name}.customer_portal.sign_off", @i18n_params)

        mail(to: to, subject: subject) do |format|
          format.mjml { render 'generic' }
          format.text { render 'invitation_customer_portal' }
        end
      else
        @strong_header_content = t("user_mailer.#{action_name}.h1", @i18n_params)
        @body_content = []

        @body_content << {type: 'copy_block', text: t("user_mailer.#{action_name}.invited_by", @i18n_params)} if @invitation.invited_by.present? || action_name == 'invitation_rerequested_inviter'
        prompt_and_expiry = "#{t("user_mailer.#{action_name}.html_click_prompt", @i18n_params)} #{@expiry.present? ? t("user_mailer.#{action_name}.expiry_prompt", @i18n_params) : ''}"
        @body_content << {type: 'copy_block', text: prompt_and_expiry} if action_name == 'invitation' || action_name == 'invitation_reminder' || action_name == 'invitation_expired_inviter' || action_name == 'invitation_rerequested_inviter' || @invitation.invited_by.present?

        case action_name
          when 'invitation', 'invitation_reminder' then
            @body_content << {
                type: 'cta',
                url: @accept_url,
                text: t("user_mailer.#{action_name}.create_account", @i18n_params)
            }
          when 'invitation_expired_invitee' then
            @body_content << {
                type: 'cta',
                url: @resubmit_invitee_url,
                text: t("user_mailer.#{action_name}.create_account", @i18n_params)
            } if @invitation.invited_by.present?
          when 'invitation_expired_inviter' then
            @body_content << {
                type: 'cta',
                url: @resubmit_inviter_url,
                text: t("user_mailer.#{action_name}.create_account", @i18n_params)
            }
          when 'invitation_rerequested_inviter' then
            @body_content << {
                type: 'text_link',
                url: @app_url,
                text: t("user_mailer.#{action_name}.create_account", @i18n_params)
            }
        end

        @body_content << {
            type: 'copy_block',
            text: t("user_mailer.shared.html_contact_prodesk", @i18n_params)
        } if @application.try(:name) == 'CONTRACTOR_PORTAL'

        @app = @application.name

        mail(to: to, from: from, subject: subject) do |format|
          format.mjml { render 'generic' }
          format.text
        end
      end
    end
  end

  def invitation_rerequested_inviter(user_application_id)
    invitation(user_application_id, 'unused', nil)
  end

  def invitation_reminder(user_application_id, raw_token, expiry)
    invitation(user_application_id, raw_token, expiry)
  end
  def invitation_expired_invitee(user_application_id, raw_token)
    user_application = UserApplication.where(id: user_application_id).first
    return if user_application.nil?
    invitation(user_application_id, raw_token, nil)
  end
  def invitation_expired_inviter(user_application_id, raw_token)
    invitation(user_application_id, raw_token, nil)
  end

  def request_assigned_requester(user_application_id)
    user_application = UserApplication.where(id: user_application_id).first
    return if user_application.nil?

    request = user_application
    user = request.user
    I18n.locale = user.preferred_language.presence || I18n.default_locale
    application = request.oauth_application
    app_name = application.try(:proper_name)
    app_name = t('user_mailer.app_name.customer_portal') if @application.try(:name) == 'CUSTOMER_PORTAL'

    @i18n_params = {
      app_name: app_name,
      name: "#{user.first_name} #{user.last_name}",
      assignee_email: request.try(:assigned_to).try(:email)
    }

    subject = t("user_mailer.#{action_name}.subject", @i18n_params)
    @app = application.name

    @header_content = t("user_mailer.#{action_name}.salutation", @i18n_params)
    @body_content = [
                      {
                        type: 'copy_block',
                        text: t("user_mailer.#{action_name}.thank_you_instructions", @i18n_params)
                      },
                      {
                        type: 'copy_block',
                        text: t("user_mailer.#{action_name}.contact_instructions", @i18n_params)
                      }
                    ]
    @signoff = t("user_mailer.#{action_name}.sign_off", @i18n_params)

    mail(to: user.email, subject: subject) do |format|
      format.mjml { render 'generic' }
      format.text
    end
  end

  def request_assigned_assignee(user_application_id)
    user_application = UserApplication.where(id: user_application_id).first
    return if user_application.nil?

    request = user_application
    assignee = request.assigned_to
    user = request.user
    I18n.locale = assignee.preferred_language.presence || I18n.default_locale
    application = request.oauth_application
    app_name = application.try(:proper_name)
    app_name = t('user_mailer.app_name.customer_portal') if @application.try(:name) == 'CUSTOMER_PORTAL'

    @i18n_params = {
      app_name: app_name,
      name: "#{assignee.first_name} #{assignee.last_name}",
      assignee_email: request.try(:assigned_to).try(:email)
    }

    subject = t("user_mailer.#{action_name}.subject", @i18n_params)
    @app = application.name
    @complete_registration_url = "#{application.real_application_uri}/registration/process?email=#{user.email}"
    @body_content = [
      {
        type: 'copy_block',
        text: t("user_mailer.#{action_name}.html_completion_prompt", @i18n_params)
      },
      {
        type: 'cta',
        url: @complete_registration_url,
        text: t("user_mailer.#{action_name}.complete_request")
      }
    ]

    @signoff = t("user_mailer.#{action_name}.sign_off", @i18n_params)

    mail(to: assignee.email, subject: subject) do |format|
      format.mjml { render 'generic' }
      format.text
    end
  end
end
