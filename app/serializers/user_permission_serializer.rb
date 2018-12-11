class UserPermissionSerializer < BaseSerializer
	attributes :application, :permission, :value

	def application
		object.permission_type.oauth_application.name
	end

	def permission
		object.permission_type.code
	end
end
