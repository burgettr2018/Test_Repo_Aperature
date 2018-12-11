class Api::V1::UsersController  < Api::V1::ApiController
  include Devise
  include CustomerPortalHelper

  skip_before_action  :load_user, only: [:validate_jwt]
  before_action :check_application_permission, except: [:me, :jwt, :validate_jwt, :find, :show, :show_by_email]
  set_headers only: :list_by_permission

  #https://aaronparecki.com/articles/2012/07/29/1/oauth2-simplified
  def me
    dk_token = doorkeeper_token
    #if given and access token, look that up
    if(params[:access_token])
			dk_token = nil
			components = params[:access_token].try(:split, '.')
			if components.present? && components.length > 1
				# has a period, try JWT
				begin
					jwt = JwtHelper.decode(params[:access_token])
					dk_token = Doorkeeper::AccessToken.find(jwt['token'])
					dk_token = nil if dk_token.resource_owner_id != jwt['sub']
				rescue
				end
			else
				dk_token = Doorkeeper::AccessToken.where(token: params['access_token']).last
			end
    end

    head :unauthorized and return if dk_token.blank? || dk_token.revoked? || dk_token.expired?

    if dk_token.resource_owner_id.blank?  #https://github.com/doorkeeper-gem/doorkeeper/wiki/Client-Credentials-flow
      @application = dk_token.application
      render
    else
      @user = User.find(dk_token.resource_owner_id)
      render json: @user, serializer: UserSerializer
    end
  end

  def jwt
    dk_token = doorkeeper_token
    if(params[:access_token])
      dk_token = Doorkeeper::AccessToken.where(token: params['access_token']).last
    end

    jwt = JwtHelper.from_access_token(dk_token)
    if jwt
      return head :ok, jwt: jwt
    end
    head :not_found
  end

  def validate_jwt
    jwt = JwtHelper.decode(params[:jwt])
    dk_token = Doorkeeper::AccessToken.find(jwt['token'])
    user = User.find(jwt['sub'])
    render json: {
        token: jwt['token'],
        sub: jwt['sub'],
        dk_token: dk_token ? {
            resource_owner_id: dk_token.resource_owner_id,
            revoked: dk_token.revoked?,
            expired: dk_token.expired?,
            expires_in: dk_token.expires_in_seconds
        } : 'invalid',
        user: user ? {
            email: user.email
        } : 'invalid'
    }
  end

  def validate
    authorize User, :authenticate?
    user = User.find_for_database_authentication(login: params[:username])
    render json: user, serializer: UserSerializer and return if user && (user.valid_password? params[:password])
    forbidden
  end

  def find
    authorize User, :show?
    @user = User.find_for_authentication(find_params)
    not_found and return if @user.blank?
    render json: @user, serializer: UserSerializer
  end

  def show
    authorize User, :show?
    @user = User.find_for_authentication(email: params[:id]) if(params[:id].to_s.include?('@'))
    @user = User.find_by(id: params[:id]) if @user.blank?
    not_found and return if @user.blank?
    render json: @user, serializer: UserSerializer
  end

  def show_by_email
    show
  end

  def current_application
    OauthApplication.find_by_name(current_application_name)
  end

  def send_invite?(invitation_expires_in, user_application)
    invitation_expires_in.present? && (!user_application.postpone_invite || user_application.request_status == 'complete')
  end

  def create_with_permissions
    authorize User, :create?

    user_params = user_create_params

    if current_application.invitation_expiry_days.present?
      # this application is subject to invitation/re-invitation
      invitation_expires_in = current_application.invitation_expiry_days.to_i.days
    end

    created_by_id = User.find_by_email(user_params[:created_by_email]).try(:id) if user_params[:created_by_email].present?

    created = false
    updated = false
    email_updated = false
    status_updated = false

    if user_params[:external_id].present?
      # find by external_id (for the application), if present, update (including email), email can be updated if provider = database
      @user = User.joins(:user_applications).where(user_applications: {oauth_application: current_application, external_id: user_params[:external_id]}).first
      if @user.nil?
        user = User.find_for_authentication(email: user_params[:email])
        current_ua = user.present? ? user.application(current_application_name) : nil
        if user.present? && current_ua.nil?
          # this user exists by mail, but not in this application, ok to join by mail
          @user = user
        elsif current_ua.present? && current_ua.external_id.nil?
          # this user does exist in application, just not with this external id
          # we can allow this if the existing external_id is nil only
          @user = user
          current_ua.update_columns(external_id: user_params[:external_id])
        end
      end
    else
      # add/update by email
      @user = User.find_for_authentication(email: user_params[:email])
    end

    #First check if user exists
    old_username = @user.username if @user.present?
    if !@user.present?
      password = Devise.friendly_token.first(8)

      @user = User.create!({
                               email: user_params[:email],
                               password: password,
                               first_name: user_params[:first_name],
                               last_name: user_params[:last_name],
                               username: user_params[:username],
                               skip_password_complexity_validation: true,
                               created_by_id: created_by_id,
                               preferred_language: user_params[:language]
                           }) do |u|
        ua = UserApplication.new(oauth_application: current_application,
                                 external_id: user_params[:external_id],
                                 postpone_invite: application_params[:postpone_invite] ? true : false,
                                 invitation_status: application_params[:postpone_invite] && application_params[:request_status] != 'complete' ? 'inactive' : nil,
                                 assigned_to_id: application_params[:assigned_to],
                                 form_submit_id: application_params[:form_submit_id],
                                 request_status: application_params[:request_status],
                                 application_data: user_params[:application_data])
        u.user_applications << ua
      end

      Rails.logger.info("Created user '#{@user.username}'#{user_params[:external_id].present? ? ", ext id: '#{user_params[:external_id]}'" : ''}, app: '#{current_application_name}'")

      # did this out here, because "invite" initiates a mailer, wanted to be sure records were saved first
      ua = @user.user_applications.first
      if send_invite?(invitation_expires_in, ua)
        ua.invite(created_by_id, invitation_expires_in)
      elsif ua.postpone_invite && ua.request_status == 'pending'
        ua.notify_assignment
      end

      # some special actions based on application user is being created for
      # TODO move this to "invitation process"
      application = current_application.name.upcase
      if application == 'FATOUT' || application == 'INSTALLED-SERVICES'
        UserMailer.application_welcome(@user, password, application, request).deliver_now
      end
      created = true
      existing_user_permissions = UserPermission.none
      old_permissions_hash = User.get_permissions_hash(existing_user_permissions)
    else
      existing_user_permissions = User.get_current_application_permissions(@user.user_permissions, @current_user, current_application)
      old_permissions_hash = User.get_permissions_hash(existing_user_permissions)

      if user_params[:email].present? && @user.email != user_params[:email]
        # if new email already exists, see if we can join
        existing_user = User.where(email: user_params[:email]).first
        user_application = UserApplication.find_by(user_id: existing_user.try(:id),
                                                   oauth_application: current_application)
        if existing_user.present? && (user_application.nil? || user_application.external_id == user_params[:external_id])
          # we can join existing user if there is no UA or it matches the param
          # old user gets permissions removed and UA removed
          old_user_application = UserApplication.find_or_create_by!(user_id: @user.id,
                                                                    oauth_application: current_application)
          old_user_application.destroy if old_user_application.external_id == user_params[:external_id] && old_user_application.present?
          existing_user_permissions.destroy_all
          @user = existing_user
        else
          # we can just update the users email address
          @user.email = user_params[:email]
          email_updated = true
          # if they are already invited, we need to resend the invitation.  probably in this case was bad email so they never got it...
          old_user_application = UserApplication.where(user_id: @user.id,
                                                       oauth_application: current_application).first
          if old_user_application.present? && old_user_application.invitation_status == 'invited'
            # we recreate it since delayed_job loads by id and we don't want old expirys/reminders to send again
            old_user_application.destroy
            ua = UserApplication.find_or_create_by!(user_id: @user.id,
                                                                  oauth_application: current_application) do |ua|
              ua.external_id = user_params[:external_id]
              ua.postpone_invite = application_params[:postpone_invite] ? true : false
              ua.invitation_status = 'inactive' if application_params[:postpone_invite] && application_params[:request_status] != 'complete'
              ua.assigned_to_id = application_params[:assigned_to]
              ua.form_submit_id = application_params[:form_submit_id]
              ua.request_status = application_params[:request_status]
              ua.application_data = user_params[:application_data]
            end
            if send_invite?(invitation_expires_in, ua)
              ua.invite(created_by_id, invitation_expires_in)
            elsif ua.postpone_invite && ua.request_status == 'pending'
              ua.notify_assignment
            end
          end
        end
      end

      @user.username = user_params[:username] if user_params[:username].present?
      @user.first_name = user_params[:first_name] if user_params[:first_name].present?
      @user.last_name = user_params[:last_name] if user_params[:last_name].present?

      user_application = UserApplication.find_or_create_by!(user_id: @user.id,
                                                            oauth_application: current_application) do |ua|
        ua.postpone_invite = application_params[:postpone_invite] ? true : false
        ua.invitation_status = 'inactive' if application_params[:postpone_invite] && application_params[:request_status] != 'complete'
        ua.assigned_to_id = application_params[:assigned_to]
        ua.form_submit_id = application_params[:form_submit_id]
        ua.request_status = application_params[:request_status]
        ua.application_data = user_params[:application_data]
      end
      attrs = {}
      attrs = attrs.merge(external_id: user_params[:external_id]) unless user_application.external_id == user_params[:external_id]
      attrs = attrs.merge(request_status: application_params[:request_status]) unless user_application.request_status == application_params[:request_status]
      attrs = attrs.merge(postpone_invite: application_params[:postpone_invite]) unless user_application.postpone_invite == application_params[:postpone_invite]
      attrs = attrs.merge(application_data: user_params[:application_data]) unless HashDiff.diff(user_application.application_data||{}, user_params[:application_data]||{}).empty?
      user_application.update_attributes(attrs) unless attrs.blank?

      # check invitation status, if applicable
      if send_invite?(invitation_expires_in, user_application)
        # this application is subject to invitation/re-invitation
        application_invite = @user.application(current_application.name)
        if application_invite.invitation_status.nil? || application_invite.invitation_status == 'expired' || application_invite.invitation_status == 'inactive'
          # re-invite
          application_invite.invite(created_by_id, invitation_expires_in)
          status_updated = true
        end
      elsif user_application.postpone_invite && user_application.request_status == 'pending'
        user_application.notify_assignment
      elsif RceHelper.is?(current_application) && invitation_expires_in.present?
        # TODO i hate putting in hacks for an application, especially in the controller
        application_invite = @user.application(current_application.name)
        if application_invite.invitation_status.nil? || application_invite.invitation_status == 'expired' || application_invite.invitation_status == 'inactive'
          # not really, but this will kick over to MDMS, which will decide based on contractor data if it wants to re-invite
          rce_reinvite = true
        end
      end

      updated = @user.changed? || email_updated || status_updated || rce_reinvite
      @user.save! if updated
    end

    # clean out existing permissions for applications calling user has access to
    @user.update_permissions_from_hash(user_params[:permissions], @current_user, current_application)

    new_permissions_hash = User.get_permissions_hash(User.get_current_application_permissions(@user.user_permissions, @current_user, current_application))

    permissions_updated = new_permissions_hash != old_permissions_hash

    updated = updated || permissions_updated
    updated = false if created
    Rails.logger.info("Updated user '#{old_username}'#{old_username != @user.username ? ", new username: '#{@user.username}'" : ''}#{user_params[:external_id].present? ? ", ext id: '#{user_params[:external_id]}'" : ''}, app: '#{current_application_name}'") if updated

    Rails.logger.debug("User - created: #{created}, updated: #{updated}")

    # this is a special case for mdms to catch up user name/email/permissions when status isn't changing
    if !status_updated && (updated || permissions_updated)
      if RceHelper.is?(current_application)
        RceHelper.update_mdms_on_user_edit(@user)
      end
    end

    render json: @user, serializer: UserSerializer
  rescue ActiveRecord::RecordInvalid => e
    if (e.record.errors.details[:email]||[]).select{|err| err[:error] == :invalid}.any?
      UserEmailValidationFailure.log(user_params, @current_application)
    end
    raise
  end

  def edit_with_permissions
    authorize User, :edit?
    @user = User.find_for_authentication(email: params[:email])
    code =  params['permission_type_code']||params['code']
    return render json:{error:"Must specify a permission 'code' to update"} if code.blank?

    permission_type = PermissionType.find_or_create_by!(code: code, oauth_application_id: current_application_id)
    user_permission = UserPermission.find_or_initialize_by(user_id: @user.id, permission_type_id:permission_type.id)
    user_permission.value = params[:value]
    user_permission.save!
    render json: @user, serializer: UserSerializer
  end

  def delete_user
    authorize User, :destroy?

    user_params = user_delete_params
    if user_params[:external_id].present?
      # find by external_id (for the application), if present, update (including email), email can be updated if provider = database
      @user = User.joins(:user_applications).where(user_applications: {oauth_application: current_application, external_id: user_params[:external_id]}).first
    else
      # add/update by email
      @user = User.find_for_authentication(email: user_params[:email])
    end
    if @user.present?
      Rails.logger.info("Deleting user '#{@user.username}'#{user_params[:external_id].present? ? ", ext id: '#{user_params[:external_id]}'" : ''}, app: '#{current_application_name}'")

      if params['oauth_application'].blank?
        permission_type = PermissionType.where(oauth_application_id: current_application_id)
        UserPermission.where(user_id: @user.id, permission_type: permission_type).destroy_all
      elsif params['oauth_application'].upcase == "CUSTOMER_PORTAL"
        permission_code_ids = PermissionType.select('id').where("code IN (?)", CP_PERMISSION_TYPE_CODES).map {|p| p.id}
        UserPermission.where("user_id = ? AND permission_type_id IN (?)", @user.id, permission_code_ids).delete_all
      else
        raise "Unknown Oauth application"
      end

      @user.reload
      RceHelper.is?(current_application) do
        RceHelper.update_user_auth_status(@user)
      end
      UserApplication.where(user_id: @user.id, oauth_application: current_application).delete_all

      #if a permission type isn't being used, delete it.
      #TODO permission_type.delete if UserPermission.where(permission_type_id: permission_type.id).count == 0

      @user.reload

      render json: @user, serializer: UserSerializer
    else
      head status: 204
    end
  end

  def delete_user_permission
    authorize User, :destroy?
    @user = User.find_for_authentication(email: params[:email])
    code =  params['permission_type_code']||params['code']
    return render json:{error:"Must specify a permission 'code' to delete"} if code.blank?

    permission_type = PermissionType.find_or_create_by!(code: code, oauth_application_id: current_application_id)
    UserPermission.where(user_id: @user.id, permission_type_id: permission_type.id).delete_all

    #if a permission type isn't being used, delete it.
    #TODO permission_type.delete if UserPermission.where(permission_type_id: permission_type.id).count == 0

    render json: @user, serializer: UserSerializer
  end

  def for_asm
    authorize User, :show?
    email_addresses = params[:email_addresses]
    users = User.joins(:user_permissions).where("users.email IN (?)", email_addresses).distinct
    @collection = users.each { |user| UserSerializer.new user }
    render json: @collection
  end

  def list_by_permission
    authorize User, :show?
    count = 100
    page  = 1

    count = params[:count].to_i if params[:count].present?
    page  = params[:page].to_i if params[:page].present?

    code = params['permission_type_code']||params['code']
    return render json:{error:"Each permission must have a 'code' property associated with it"} if code.blank?
    users = User.joins(:permission_types).joins(:user_permissions).where(permission_types: { code: code, oauth_application_id:current_application_id}).uniq

    if params[:q].present?
      users = users.where("first_name LIKE ? OR last_name LIKE ? OR email LIKE ? OR user_permissions.value LIKE ?", "#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%")
    end

    dir = case params[:dir].try(:downcase)
            when 'asc' then 'asc'
            when 'desc' then 'desc'
            else 'asc'
          end
    if params[:sort].present? && User.column_names.include?(params[:sort])
      users = users.order("#{params[:sort]} #{dir}")
    end

    @collection = users.page(page||1).per(count)
    render json: @collection, serializer: UserListSerializer
  end

  def applications
    applications = UserApplication.all
    applications = applications.where(user_id: params[:user_id]) if params[:user_id].present?
    applications = applications.where(invited_by_id: params[:invited_by_id]) if params[:invited_by_id].present?
    applications = applications.where(invitation_status: params[:invitation_status]) if params[:invitation_status].present?
    applications = applications.where(assigned_to_id: params[:assigned_to_id]) if params[:assigned_to_id].present?
    applications = applications.where(request_status: params[:request_status]) if params[:request_status].present?
    applications = applications.joins(:oauth_application).where(oauth_applications: {name: params[:application_name]}) if params[:application_name].present?

    render json: applications.as_json
  end

  private
  def find_params
    params.permit(:id, :username, :email, :guid, :login)
  end
  def current_application_id
    OauthApplication.find_by_name(current_application_name).try(:id)
  end
  def current_application_name
    application_params.try(:[], :application) || @current_application.name
  end

  def application_params
    app_name = @current_application.try(:name)
    filters = %i(postpone_invite assigned_to form_submit_id request_status)
    if (@current_user.present? && @current_user.has_permission?('UMS', 'CROSS_APPLICATION_PERMISSIONS', params[:application])) || (@current_application.present? && params[:application] == @current_application.name)
      filters << :application
      app_name = params[:application] || app_name
    end
    permitted = params.permit(*filters)
    permitted[:postpone_invite] = OauthApplication.find_by_name(app_name).try(:postpone_all_invites) if permitted[:postpone_invite].nil?
    permitted
  end

  def check_application_permission
    forbidden unless @current_user.has_permission?('UMS', 'CROSS_APPLICATION_PERMISSIONS', params[:application]) || params[:application] == @current_application.name || params[:application].blank?
  end

  def user_delete_params
    # convert to snake_case if needed
    user_params = snakecase_params

    # normalize alternate field names (contact -> external_id, user_permissions -> permissions, permissions.permission_type_code -> permission, permissions.code -> permission)
    fix_param_name user_params, :contact, :external_id

    # permits
    user_params = user_params.permit(:external_id, :email)

    user_params
  end

  def user_create_params
		user_params = User.normalize_param_hash(snakecase_params, @current_user, current_application)

		# permits
		permission_permits = %i(permission application value)
		permitted_params = user_params.permit(:external_id, :email, :created_by_email, :first_name, :last_name, :username, :language, permissions: permission_permits)

    permitted_params.merge(application_data: user_params[:application_data])
	end

  def fix_param_name(param_collection, from, to)
    new_param = {}
    new_param[to] = param_collection[from]
    param_collection.merge!(new_param).extract!(from) if param_collection[from].present? && !param_collection[to].present?
  end
end
