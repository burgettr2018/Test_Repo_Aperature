require 'rails_helper'
require 'securerandom'
require './spec/helpers/delayed_job_spec_helper.rb'

RSpec.describe Contractor::RceVirtualAdfsUser, type: :model, pending: "Refactor the wazjub for easier frobbing" do
	include DelayedJobSpecHelper

	let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'CONTRACTOR_PORTAL') }

	let!(:permission_type) { create(:permission_type, code: 'LOCATION', application: application.name) }
  let!(:user) { create(:user, application: application.name, permissions: []) }

	context "adfs sync" do
    before do
			clear_jobs
      Timecop.freeze(Time.local(1990))
    end

    after do
      Timecop.return
    end

    it "queues an adfs sync task for additions" do
      uuid = SecureRandom.uuid
      expect{Contractor::RceVirtualAdfsUser.create!(user_id: user.id, location_guid: uuid)}.to change{ job_count }
		end
    it "executes an adfs sync task for additions" do
      uuid = SecureRandom.uuid
			Contractor::RceVirtualAdfsUser.create!(user_id: user.id, location_guid: uuid)
			vuser = Contractor::RceVirtualAdfsUser.first
			expect(TransactionalPortalHelper).to receive(:add_or_enable_ad_user).with(vuser.username, vuser.email, user.first_name, user.last_name, anything)
			expect(TransactionalPortalHelper).to receive(:get_ad_user_name_by_email).with(vuser.email).and_return(vuser.username)
      expect(perform_jobs).to eq [1, 0]
    end
	end
end
