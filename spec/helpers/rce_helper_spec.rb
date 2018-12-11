require "rails_helper"
require './spec/helpers/delayed_job_spec_helper.rb'

describe RceHelper do
	include DelayedJobSpecHelper

	describe "update_mdms_on_user_edit" do
		let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'CONTRACTOR_PORTAL') }
		let!(:application_ums) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'UMS') }
		let!(:existing_user) { create(:user, application: application.name, permissions: %w(TEST1)) }
		it "calls MDMS with snakecase params" do
			stub_request(:post, "#{RceHelper::MDMS_URL}/api/v1/contractor/users").
					with(body: /auth_status/)
			RceHelper.update_mdms_on_user_edit(existing_user)
			expect(perform_jobs).to eq [1, 0]
		end
	end
end