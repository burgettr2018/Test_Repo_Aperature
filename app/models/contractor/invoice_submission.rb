class Contractor::InvoiceSubmission < Contractor::ContractorBase
	self.table_name = 'contractor_invoice_submissions'

	belongs_to :user, primary_key: "guid", foreign_key: "user_guid"

	rails_admin do
		parent Contractor::MemberProfile
		label 'Invoice Submissions'
		list do
			include_fields :id, :membership_number, :user, :invoice_type, :submitted_at, :processed_at, :s3_attachment_key
		end
	end
end
