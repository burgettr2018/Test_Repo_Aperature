class Contractor::PqsWarrantyRegistration < Contractor::ContractorBase
	self.table_name = 'contractor_pqs_warranty_registrations'

	rails_admin do
		parent Contractor::MemberProfile
		label 'PQS Warranty Registration (Test Endpoint)'
	end
end
