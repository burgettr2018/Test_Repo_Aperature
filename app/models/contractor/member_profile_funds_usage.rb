class Contractor::MemberProfileFundsUsage < Contractor::ContractorBase
	self.table_name = 'contractor_member_profile_funds_usages'

	belongs_to :user, primary_key: "guid", foreign_key: "user_guid"
	belongs_to :member_profile, class_name: 'Contractor::MemberProfile', primary_key: "id", foreign_key: "member_profile_id"

	rails_admin do
		parent Contractor::MemberProfile
		label 'Funds Usage'
		list do
			include_fields :id, :created_at, :requestor_name, :member_profile, :user, :amount, :total_amount, :supplemental_amount, :order_id, :order_note, :status, :available_funds, :note
		end
	end
end
