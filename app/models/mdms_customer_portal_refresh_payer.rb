class MdmsCustomerPortalRefreshPayer < ActiveRecord::Base
	establish_connection :mdms
	self.table_name = 'refresh_payers'
end
