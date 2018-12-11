class Contractor::EstoreProfile < Contractor::ContractorBase
	self.table_name = 'contractor_estore_profiles'

	belongs_to :user, primary_key: "guid", foreign_key: "user_guid"
	belongs_to :member_profile, class_name: 'Contractor::MemberProfile', primary_key: "location", foreign_key: "location"

	belongs_to :virtual_adfs_user, class_name: 'Contractor::RceVirtualAdfsUser', primary_key: :email, foreign_key: :login_name

	rails_admin do
		show do
			configure :login_name do
				show
			end
			configure :virtual_adfs_user do
				show
			end
		end
	end

end
