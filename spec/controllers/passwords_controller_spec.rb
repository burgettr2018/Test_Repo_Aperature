require "rails_helper"

describe PasswordsController do
	let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application') }
	let!(:invited_user) { create(:user, :with_future_invitation, application: application.name, permissions: [{code: 'TEST1'}]) }
	let!(:raw) { invited_user.send_reset_password_instructions }

	before do
		request.env['devise.mapping'] = Devise.mappings[:user]
	end

	let(:update) do
		->() {
			put :update, user: {
				reset_password_token: raw, password: "Password1!", password_confirmation: "Password1!"
			}
		}
	end

	it "signs in and updates status" do
		update.call
		expect(subject.current_user).to be
		expect(subject.current_user.user_applications.first.invitation_status).to eq('complete')
		expect(subject.current_user.user_applications.first.invitation_token).to be_nil
		expect(subject.current_user.sign_in_count).to eq(1)
		expect(subject.current_user.log_in_count).to eq(0)
		expect(subject.current_user.password_changed_count).to eq(1)
		expect(subject.current_user.devise_log_histories.first.date.to_date).to eq(Date.current)
		expect(subject.current_user.devise_log_histories.first.devise_action).to eq('password_changed')
	end
end
