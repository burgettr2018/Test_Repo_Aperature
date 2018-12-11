class Contractor::ImpersonationLog < ActiveRecord::Base
	belongs_to :user
	belongs_to :impersonated_user, class_name: User
end
