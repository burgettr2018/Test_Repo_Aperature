class Contractor::PqsProfile < Contractor::ContractorBase
	self.table_name = 'contractor_pqs_profiles'

	has_many :member_profiles, class_name: 'Contractor::MemberProfile', primary_key: "membership_number", foreign_key: "membership_number"

	rails_admin do
		parent Contractor::MemberProfile
		label 'PQS Profile'
	end

end
