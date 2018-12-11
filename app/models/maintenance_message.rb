class MaintenanceMessage < ActiveRecord::Base
	belongs_to :oauth_application
	belongs_to :created_by, class_name: User

	scope :active, -> { where('(start_date_utc IS NULL OR start_date_utc < ?) AND (end_date_utc IS NULL OR end_date_utc > ?)', DateTime.current.utc, DateTime.current.utc) }

	rails_admin do
		parent OauthApplication
		create do
			include_fields :oauth_application, :start_date_utc, :end_date_utc
			field :created_by_id, :hidden do
				visible true
				default_value do
					bindings[:controller].current_user.id
				end
			end
		end
	end
end