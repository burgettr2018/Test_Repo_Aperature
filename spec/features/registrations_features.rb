require "../rails_helper"

feature "accept invitation" do
	#include ActiveSupport::Testing::TimeHelpers
	let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application') } # OAuth application
	let!(:creator) { create(:user, application: application.name, permissions: %w(TEST1)) }
	let!(:invited_user) { create(:user, :with_future_invitation, created_by_id: creator.id, application: application.name, permissions: [{code: 'TEST1'}]) }
	let!(:expired_user) { create(:user, :with_expired_invitation, application: application.name, permissions: %w(TEST1)) }

	it "accepts valid invitation" do
		visit "/users/invitations/accept/#{invited_user.invitation_token}"
		expect(page).to have_field('password')
		expect(page).to have_field('password_confirmation')
	end
end
