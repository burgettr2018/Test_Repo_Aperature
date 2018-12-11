class MdmsEmployee < ActiveRecord::Base
	establish_connection :mdms
	self.table_name = 'employees'
	self.primary_key = 'employee_id'
end