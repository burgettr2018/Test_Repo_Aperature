require "rails_helper"

describe ApplicationController do
	include Devise::Test::ControllerHelpers
	before do
		request.env['devise.mapping'] = Devise.mappings[:user]
	end

	let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application') }
	let!(:existing_user) { create(:user, :with_invitation_token, application: application.name, permissions: %w(TEST1)) }

	it "updates status to 'complete' when signing in from invited/re-invited" do
		expect(existing_user.application(application.name).invitation_status).to eq('invited')
		sign_in existing_user
		warden.set_user existing_user, {}
		expect(existing_user.application(application.name).invitation_status).to eq('complete')
	end
end