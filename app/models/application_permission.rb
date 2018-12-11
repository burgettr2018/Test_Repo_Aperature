class ApplicationPermission < ActiveRecord::Base
  belongs_to :oauth_application, inverse_of: :application_permissions
  belongs_to :permission_type

  validates_presence_of :oauth_application, :permission_type

  def name
    "#{permission_type.try(:code)} - #{value}"
  end

  rails_admin do
    parent OauthApplication
  end
end
