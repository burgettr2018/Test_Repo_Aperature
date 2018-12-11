require "rails_helper"

describe InternalController do

	def permission_to_s(permissions)
		permissions.to_a.map{|p| {
				application: p.permission_type.oauth_application.name,
				code: p.permission_type.code,
				value: p.value
		}}.to_json
	end

	let(:application) { create(:oauth_application) }
	let(:active_user) { create(:user, admin: true ) }
	let(:hidden_id) { nil }
	let(:mdms_employee) { create(:mdms_employee) }
	let(:employee_id) { mdms_employee.employee_id }
	let(:permissions) {
		[]
	}
	let(:post_hash) {
		hash = {
			hidden_id: hidden_id,
			employee_id: employee_id
		}
		(permissions||[]).each do |p|
			perm = create(:permission_type, application: application.name, code: p[:code], is_for_employees: true, is_value_required: p[:req].to_b)
			hash.merge!({
					:"pt_#{perm.id}" => "1"
									})
			if p[:value] != '*'
				hash.merge!({
						:"value_#{perm.id}" => p[:value]
										})
			end
		end
		hash
	}
	let(:post_data) {
		{
			internal_user: (post_hash||{})
		}
	}

	before do
		request.env['devise.mapping'] = Devise.mappings[:user]
		sign_in active_user, scope: :user
	end

	subject {
		post :create, post_data
	}

	context "new user" do
		context "no value" do
			let(:permissions) {
				[
						{code: 'TEST1', value: '*'},
						{code: 'TEST2', value: '*'},
				]
			}
			it "creates a user record for the permissions" do
				subject
				user = User.find_by_email(mdms_employee.email_address)
				expect(user).to be
				expect(user.user_permissions.count).to eq(2)
				expect(permission_to_s(user.user_permissions)).to eq([{
																																	application: application.name,
																																	code: 'TEST1',
																																	value: '*'
																															},
																															{
																																	application: application.name,
																																	code: 'TEST2',
																																	value: '*'
																															}].to_json)
			end
		end
		context "value" do
			let(:permissions) {
				[
						{code: 'TEST1', value: '1,2', req: true},
						{code: 'TEST2', value: '*'},
				]
			}
			it "creates a user record for the permissions" do
				subject
				user = User.find_by_email(mdms_employee.email_address)
				expect(user).to be
				expect(user.user_permissions.count).to eq(2)
				expect(permission_to_s(user.user_permissions)).to eq([{
																																	application: application.name,
																																	code: 'TEST1',
																																	value: '1,2'
																															},
																															{
																																	application: application.name,
																																	code: 'TEST2',
																																	value: '*'
																															}].to_json)
			end
		end
	end
	context "existing user" do
		before do
			create(:user, email: mdms_employee.email_address, permissions: [{application: application.name, code: 'TEST3'}])
		end
		let(:permissions) {
			[
					{code: 'TEST1', value: '*'},
					{code: 'TEST2', value: '*'},
			]
		}
		it "updates a user record for the permissions" do
			user = User.find_by_email(mdms_employee.email_address)
			expect(user.user_permissions.count).to eq(1)
			expect(user).to be
			subject
			user2 = User.find_by_email(mdms_employee.email_address)
			expect(user2).to be
			expect(user.id).to eq(user2.id)
			expect(user2.user_permissions.count).to eq(3)
			expect(permission_to_s(user2.user_permissions)).to eq([{
																																application: application.name,
																																code: 'TEST3',
																																value: '*'
																														},
																														{
																																application: application.name,
																																code: 'TEST1',
																																value: '*'
																														},
																														{
																																application: application.name,
																																code: 'TEST2',
																																value: '*'
																														}].to_json)
		end
	end
end