Rails.logger.info "Extending Doorkeeper from config/initializer/doorkeeper_patch.rb"
module Doorkeeper
  class AccessToken
    has_one :api_token
  end
end
Doorkeeper::OAuth::Token.class_eval do
  class <<self
    alias_method :old_from_request, :from_request
  end
  def self.from_request(request, *methods)
    token = self.old_from_request(request, *methods)
    components = token.try(:split, '.')
    if components.present? && components.length > 1
      # has a period, try JWT
      begin
        jwt = JwtHelper.decode(token)
        token = Doorkeeper::AccessToken.find(jwt['token'])
        token = nil if token.resource_owner_id != jwt['sub']
        token = token.token unless token.nil?
      rescue
      end
    end
    token
  end
end
Doorkeeper::Application.class_eval do
  has_many :application_permissions, foreign_key: "oauth_application_id",class_name: 'ApplicationPermission',inverse_of: :oauth_application
  has_many :permission_types, foreign_key: "oauth_application_id",class_name: 'PermissionType',inverse_of: :oauth_application
  validates_uniqueness_of :name
  validates_presence_of :redirect_uri

  def permissions
    application_permissions
  end

  def has_permission?(application_name, permission_code, value = nil)
    PermissionHelper.has_permission?(permissions.eager_load(permission_type: :oauth_application).to_a, application_name, permission_code, value)
  end

  # keep adding any other methods, validations, relations here...
end
