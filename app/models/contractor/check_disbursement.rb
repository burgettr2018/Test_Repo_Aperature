class Contractor::CheckDisbursement < Contractor::ContractorBase
	self.table_name = 'check_disbursements'

	# belongs_to :member_profile, class_name: 'Contractor::MemberProfile', primary_key: "id", foreign_key: "member_profile_id"
	has_and_belongs_to_many :check_disbursement_files, class_name: 'Contractor::CheckDisbursementFile'

	class HABTM_CheckDisbursementFiles < ActiveRecord::Base
		establish_connection :mdms
	end

	rails_admin do
		parent Contractor::MemberProfile
		label 'Check Disbursements'
		list do
			include_fields :id, :member_number, :company_name, :payment_date, :payment_amount, :approver, :program_code, :tier_level, :language, :street, :city, :state, :zip, :country, :currency, :vendor, :transaction_id, :created_at
		end
	end
end
