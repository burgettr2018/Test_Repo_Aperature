class Contractor::MemberProfileFundsRequest < Contractor::ContractorBase
	self.table_name = 'contractor_member_profile_funds_requests'

	belongs_to :user, primary_key: "guid", foreign_key: "user_guid"
	belongs_to :member_profile, class_name: 'Contractor::MemberProfile', primary_key: "id", foreign_key: "member_profile_id"

	rails_admin do
		parent Contractor::MemberProfile
		label 'Funds Requests'
		list do
			include_fields :id, :created_at, :requestor_name, :member_profile, :user, :available_funds, :note
		end
	end
end
