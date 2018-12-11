class UserSerializer < BaseSerializer
	attributes :id, :type, :guid, :uid, :external_id, :username, :email, :first_name, :last_name, :name,
						 :created_by, :invited_by, :invitation_expires_at, :auth_status, :permissions, :postpone_invite

	def self.map_invitation_status_to_auth_status(application, invite_object)
		status = invite_object.try(:invitation_status)
		if RceHelper.is?(application)
			status = status.try(:titleize).try(:gsub,' ','-')
			status = 'Provisioned' if status == 'Complete'
			status = 'Removed' if status == 'Inactive'
			status = 'Expired' if status == 'Removed' && (invite_object.postpone_invite.presence||false)
		end
		status
	end

	def type
		'user'
	end
	def invitation_expires_at
		invite_object = object.application(serialization_context[:current_application].name)
		if invite_object.present? && invite_object.invitation_status == 'expired'
			nil
		else
			invite_object.current_invitation_sent_at + invite_object.invitation_expires_in if invite_object.present? && invite_object.current_invitation_sent_at.present? && invite_object.invitation_expires_in.present?
		end
	end
	def postpone_invite
		invite_object = object.application(serialization_context[:current_application].name)
		invite_object.try(:postpone_invite)
	end
	def auth_status
		invite_object = object.application(serialization_context[:current_application].name)
		UserSerializer.map_invitation_status_to_auth_status(serialization_context[:current_application], invite_object)
	end
	def permissions
		object.user_permissions.eager_load(permission_type: :oauth_application).select{
				|p|
			validate_application_access(p.permission_type)
		}.map{
				|p|
			UserPermissionSerializer.new(p, root: false, scope: serialization_context, scope_name: :serialization_context)
		}
	end

	# external_id is the application given external id
	def external_id
		application_object = object.application(serialization_context[:current_application].name)
		application_object.try(:external_id)
	end

	def invited_by
		invite_object = object.application(serialization_context[:current_application].name)
		invited_by_user = User.find_by(id: invite_object.invited_by_id) if invite_object.present? && invite_object.invited_by_id.present?
		invited_by_user.email if invited_by_user.present?
	end
	def created_by
		created_by_user = User.find_by(id: object.created_by_id) if object.created_by_id.present?
		created_by_user.email if created_by_user.present?
	end

	# remove nil invitation_expires_at
	def serializable_hash(adapter_options = nil, options = {}, adapter_instance = self.class.serialization_adapter_instance)
		hash = super

		# merge in application_data for calling application(s)
		object.user_applications.eager_load(:oauth_application).where.not(application_data: nil).each do |ua|
			hash.merge!(ua.oauth_application.name.underscore => ua.application_data) if validate_application_access(ua)
		end

		nilable_keys = %w(created_by invited_by invitation_expires_at external_id)
		hash.each { |key, value| hash.delete(key) if value.nil? && is_key_one_of?(key, nilable_keys) }
		hash
	end

	private
	def validate_application_access(obj_with_oauth_application)
		is_current_app = obj_with_oauth_application.oauth_application.id == serialization_context[:current_application].id
		is_app_with_access = serialization_context[:current_application].has_permission?(
				'UMS',
				'CROSS_APPLICATION_PERMISSIONS',
				obj_with_oauth_application.oauth_application.try(:name)
		)
		is_current_app || is_app_with_access
	end
end
