class UserPermission < ActiveRecord::Base
  include CustomerPortalHelper

  before_save :uniq_value_list

  belongs_to :user, inverse_of: :user_permissions
  belongs_to :permission_type

  validates_presence_of :user, :permission_type

  def name
    "#{permission_type.try(:code)} - #{value}"
  end

  def application
    permission_type.try(:oauth_application).try(:name)
  end

  def code
    permission_type.try(:code)
  end

  def is_customer_portal_permission
    CP_PERMISSION_TYPE_CODES.include?(self.permission_type.code) && self.permission_type.oauth_application.name == 'MDMS'
  end
  def is_customer_portal_admin_permission
    self.permission_type.oauth_application.name == 'MDMS' && self.permission_type.code == 'OA_ADMIN'
  end
  def is_contractor_portal_impersonate_permission
    self.permission_type.oauth_application.name == 'CONTRACTOR_PORTAL' && self.permission_type.code == 'IMPERSONATE'
  end

  rails_admin do
    parent User
  end

  private
  def uniq_value_list
    self.value = self.value.split(',').uniq.join(',') if self.value && self.value.include?(',')
  end
end
