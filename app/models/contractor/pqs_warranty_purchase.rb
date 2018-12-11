class Contractor::PqsWarrantyPurchase < Contractor::ContractorBase
	self.table_name = 'contractor_pqs_warranty_purchases'

	rails_admin do
		parent Contractor::MemberProfile
		label 'PQS Warranty Purchase'
	end
end
