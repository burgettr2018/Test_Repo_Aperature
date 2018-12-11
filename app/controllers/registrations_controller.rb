class RegistrationsController < Devise::RegistrationsController
  include SamlIdp::Controller
  include ApplicationHelper
  prepend_before_filter :authenticate_scope!, only: [:edit, :update, :destroy, :edit_password, :update_password, :resubmit_invitation_inviter]

  def edit_password
    set_flash_message :notice, :set_new_password
  end

  def update_password
    resource.assign_attributes(account_update_params) unless params[resource_name].nil?

    if resource.valid? && resource.password_match?
      self.resource.save!
      set_flash_message :notice, :updated
      self.resource.update_tracked_fields!(request)
      # Sign in the user bypassing validation in case password changed
      bypass_sign_in resource
      redirect_to after_update_path_for(resource)
    else
      render :action => 'edit_password'
    end
  end

  def update
    redirect_to after_update_path_for(resource) and return if !resource.is_database_provider
    super
  end

  def accept_invitation
    validate_invitation do
      # unless @user.is_database_provider
      # 	# redirect to provider if saml provider
      # 	provider_model = SamlIdentityProvider.where(token: @user.provider).first
      # 	if provider_model.present? && provider_model.idp_sso_target_url.present?
      # 		redirect_to omniauth_authorize_path(resource_name, provider)
      # 	end
      # end
    end
  end

  def accept_invitation_put
    validate_invitation do |invitation|
      @user.assign_attributes(accept_invitation_params.except(:token))
      if @user.valid? && @user.password_match?
        invitation.complete(true)
        invitation.assign_attributes(invitation_token: nil)
        invitation.save! && @user.save!
        set_flash_message :notice, :updated
        @user.update_tracked_fields!(request)
        # Sign in the user bypassing validation in case password changed
        bypass_sign_in @user

        #TODO - consider IdP initiated, https://docs.microsoft.com/en-us/dynamics365/customer-engagement/portals/configure-saml2-settings#idp-initiated-sign-in
        # if invitation.oauth_application.saml_acs.present?
        #   @saml_response
        #   @saml_response = encode_SAMLResponse(current_user['email'])
        #   Rails.logger.info Base64.decode64(@saml_response) if ENV['UMS_DEBUG_SAML'].to_b
        #   @message = t('devise.sessions.new.logging_in')
        #   @title = t('devise.sessions.new.login')
        #   render 'sso'
        # else
        redirect_to after_sign_in_path_for(@user)
        # end
      else
        render action: :accept_invitation
      end
    end
  end

  def resubmit_invitation_inviter
    user_application = UserApplication.find_by_invitation_token(params[:token])
    head status: :not_found and return if user_application.nil?
    if user_application.current_invitation_expires_at < Time.current
      if current_user.id != user_application.invited_by_id
        set_flash_message(:alert, :invitation_resubmit_original_user) and redirect_to new_user_session_path
      else
        #recreate invitation
        user_application.invite(user_application.invited_by_id, user_application.invitation_expires_in.to_i.seconds)
        render 'resubmit_invitation'
      end
    else
      head status: :unprocessable_entity
    end
  end

  def resubmit_invitation_invitee
    user_application = UserApplication.find_by_invitation_token(params[:token])
    head status: :not_found and return if user_application.nil?
    if user_application.current_invitation_expires_at < Time.current
      invited_by = user_application.invited_by
      if invited_by.present?
        user_application.request_new_invite
        set_flash_message(:notice, :invitation_resubmitted) and redirect_to new_user_session_path
      else
        # just 404 out since a "request to be re-invited" on an invitation without an invited_by is basically same as having no invitation at all
        head status: :not_found and return if user_application.nil?
      end
    else
      head status: :unprocessable_entity
    end
  end

  protected

  def validate_invitation
    user_application = UserApplication.find_by_invitation_token(params[:token])
    flash[:alert] = I18n.t('devise.failure.invitation_not_found') and redirect_to new_user_session_path and return if user_application.nil?
    @user = user_application.user

    if user_application.current_invitation_expires_at < Time.current
      expiry_override = Time.parse(params[:initiated]) <= user_application.current_invitation_expires_at rescue nil
      flash[:alert] = format_expiry_message(user_application) and redirect_to new_user_session_path and return unless expiry_override
    end

    yield(user_application) unless @user.nil?
  end

  def accept_invitation_params
    params.require(:user).permit(:token, :password, :password_confirmation, :current_password)
  end

  def parse_return_url
    session[:return_url] = params[:return_url] if !params[:return_url].blank?
  end

end
