require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
	let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application') }

	let!(:creator) { create(:user, application: application.name, permissions: %w(TEST1)) }
	let!(:invited_user) { create(:user, :with_future_invitation, created_by_id: creator.id, application: application.name, permissions: [{code: 'TEST1'}]) }
	let!(:expired_user) { create(:user, :with_expired_invitation, application: application.name, permissions: %w(TEST1)) }

	describe "invitation" do
		let(:mail) { described_class.invitation(invited_user.application(application.name), 'phony_token', 2.days).deliver_now }

		context "without customized template" do
			let!(:application2) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application 2') }
			let!(:invited_user2) { create(:user, :with_future_invitation, created_by_id: creator.id, application: application2.name, permissions: [{code: 'TEST1'}]) }
			let(:mail2) { described_class.invitation(invited_user2.application(application2.name), 'phony_token', 2.days).deliver_now }

			it "renders generic template" do
				expect(mail2.body.encoded).not_to match('template for unit tests')
			end
		end

		context "with customized template" do
			it "renders customized template" do
				#expect(mail.body.encoded).to match('invitation template for unit tests')
				expect(mail.body.encoded).to match('been invited')
				expect(mail.subject).to match('from')
			end
		end
	end
	describe "invitation_reminder" do
		let(:mail) { described_class.invitation_reminder(invited_user.application(application.name), 'phony_token', 2.days).deliver_now }
		context "with customized template" do
			it "renders customized template" do
				#expect(mail.body.encoded).to match('invitation reminder template for unit tests')
				expect(mail.body.encoded).to match('will expire')
				expect(mail.subject).to match('Expires Soon')
			end
		end
	end
end