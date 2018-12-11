class PermissionType  < ActiveRecord::Base
  include CustomerPortalHelper

  belongs_to :oauth_application

  validates_presence_of :oauth_application, :code

  has_many :user_permissions, dependent: :destroy
  has_many :application_permissions, dependent: :destroy

  def proper_name
    self[:proper_name] || code.titleize
  end

  scope :customer_portal, -> do
    includes(:oauth_application)
    .where(code: CP_PERMISSION_TYPE_CODES)
    .where("oauth_applications.name" => 'MDMS')
  end

  def name
    "#{oauth_application.try(:name)||'NONE'} - #{code}"
  end
end
