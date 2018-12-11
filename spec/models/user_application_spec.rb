require "rails_helper"

RSpec.describe UserApplication do
	it "returns 'expired' even if data is invited if expiry passed" do
		# we need status to be smart and not rely on job to set to "expired"
		invited_at = 1.day.ago
		ua = create(:user_application, invitation_status: 'invited', first_invitation_sent_at: invited_at, current_invitation_sent_at: invited_at, invitation_expires_in: 2.days)
		expect(ua.invitation_status).to eq('invited')

		invited_at = 3.days.ago
		ua = create(:user_application, invitation_status: 'invited', first_invitation_sent_at: invited_at, current_invitation_sent_at: invited_at, invitation_expires_in: 2.days)
		expect(ua.invitation_status).to eq('expired')
	end

	it "expires accounts after expiry date" do
		invited_at = 3.days.ago
		ua = create(:user_application, invitation_status: 'invited', first_invitation_sent_at: invited_at, current_invitation_sent_at: invited_at, invitation_expires_in: 2.days)
		expect(ua[:invitation_status]).to eq('invited')
		UserApplication.expire_invites
		ua.reload
		expect(ua[:invitation_status]).to eq('expired')
	end

	it "marks invitation as reminded when reminded" do
		ua = create(:user_application)
		ua.invite nil, 4.days
		expect(ua[:invitation_status]).to eq('invited')

		expect(ua.reminded).to be_falsey
		ua.remind
		expect(ua.reminded).to be_truthy
	end

	it "allows searching by status" do
		invited_at = 1.days.ago
		ua = create(:user_application, invitation_status: 'invited', first_invitation_sent_at: invited_at, current_invitation_sent_at: invited_at, invitation_expires_in: 2.days)
		expect(ua[:invitation_status]).to eq('invited')

		expect(UserApplication.for_invitation_status('invited').count).to eq(1)
		expect(UserApplication.for_invitation_status('invited').first.id).to eq(ua.id)

		expect(UserApplication.for_invitation_status('expired').count).to eq(0)

		ua.update_attributes(invitation_status: 'expired')

		expect(UserApplication.for_invitation_status('expired').count).to eq(1)
		expect(UserApplication.for_invitation_status('expired').first.id).to eq(ua.id)

		expect(UserApplication.for_invitation_status('invited').count).to eq(0)
	end
	it "allows searching by virtual expired status" do
		invited_at = 3.days.ago
		ua = create(:user_application, invitation_status: 'invited', first_invitation_sent_at: invited_at, current_invitation_sent_at: invited_at, invitation_expires_in: 2.days)
		expect(ua[:invitation_status]).to eq('invited')

		expect(UserApplication.for_invitation_status('expired').count).to eq(1)
		expect(UserApplication.for_invitation_status('expired').first.id).to eq(ua.id)

		expect(UserApplication.for_invitation_status('invited').count).to eq(0)
	end
end
