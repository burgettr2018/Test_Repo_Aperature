class Contractor::CheckDisbursementFile < Contractor::ContractorBase
	self.table_name = 'check_disbursement_files'

	has_and_belongs_to_many :check_disbursements, class_name: 'Contractor::CheckDisbursement'

	class HABTM_CheckDisbursements < ActiveRecord::Base
		establish_connection :mdms
	end

	rails_admin do
		label 'Check Disbursement PI Files'
		list do
			include_fields :id, :filename, :status, :message, :created_at
		end
	end
end
