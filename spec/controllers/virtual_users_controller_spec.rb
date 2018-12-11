require "rails_helper"

describe Api::V1::VirtualUsersController do
	let!(:application) { create(:oauth_application, :with_virtual_user_manage_permission, name: 'Sample Application') }
	let!(:application_token) { create(:access_token, application: application) }

	let!(:valid_location) { SecureRandom.uuid }
	let!(:invalid_location) { SecureRandom.uuid }

	before do
		allow(controller).to receive(:doorkeeper_token) { application_token }
		stub_request(:post, ENV['UMS_USER_SERVICE_WSDL'].gsub(/\?wsdl$/, '')).
				with(headers: { 'Soapaction'=>'"http://tempuri.org/IUserService/GetUserDetailsByEmailAddress"'}).
				to_return(status: 200, body: File.read('spec/fixtures/transactional_portal_helper/get_user_details_by_email_address/success.xml'), headers: {})
	end

	describe "enable" do
		let(:enable) do
			->(user) {
				post :enable, user: user
			}
		end

		context "global user" do
			let!(:existing_user) { create(:user, application: 'CONTRACTOR_PORTAL', permissions: [
					{code: 'LEVEL', value: 'GLOBAL'},
					{code: 'ACCOUNT', value: 'A'}
			]) }

			it "enables the user" do
				expect{enable.call(guid: existing_user.guid, account: 'A', location: valid_location)}.to change{Contractor::RceVirtualAdfsUser.count}.from(0).to(1)
				expect(response).to be_success
			end
		end
		context "location user" do
			let!(:existing_user) { create(:user, application: 'CONTRACTOR_PORTAL', permissions: [
					{code: 'LEVEL', value: 'LOCATION'},
					{code: 'ACCOUNT', value: 'A'},
					{code: 'LOCATION', value: valid_location}
			]) }

			it "enables the user if valid" do
				expect{enable.call(guid: existing_user.guid, account: 'A', location: valid_location)}.to change{Contractor::RceVirtualAdfsUser.count}.from(0).to(1)
				expect(response).to be_success
			end
			it "does nothing if the user invalid" do
				expect{enable.call(guid: existing_user.guid, account: 'A', location: invalid_location)}.not_to change{Contractor::RceVirtualAdfsUser.count}
				expect(response).to have_http_status(400)
			end
		end
	end
end
