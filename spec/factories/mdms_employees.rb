FactoryBot.define do
	factory :mdms_employee do
		initialize_with {
			response = MdmsEmployee.where(employee_id: employee_id).first_or_initialize(attributes)
			response.assign_attributes(attributes) unless response.nil?
			response
		}
		first_name { 'John' }
		sequence(:last_name, 1000) { |n| "Smith #{n}" }
		sequence(:email_address, 1000) { |n| "person#{n}@owenscorning.com" }
		sequence(:employee_id, 1000) { |n| "90#{n.to_s.rjust(4, "0")}"}
	end
end
