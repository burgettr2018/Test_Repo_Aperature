module PermissionHelper
	def self.has_permission?(permissions, application_name, permission_code, value = nil)
		!permissions.find {|p|
			p.permission_type.oauth_application.name.casecmp(application_name) == 0 && p.permission_type.code.casecmp(permission_code) == 0 && (p.value.blank? || p.value.casecmp('*') == 0 || (!value.blank? && p.value.split(',').include?(value)))
		}.blank?
	end
	def self.get_permission_value(permissions, application_name, permission_code)
		if permissions.blank?
			return nil
		else
			return permissions.detect{|p|p.permission_type.oauth_application.name.casecmp(application_name) == 0 && p.permission_type.code.casecmp(permission_code) == 0}.try(:value)
		end
	end
end
