require "rails_helper"

describe RegistrationsController do
  let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application') }

  before do
		request.env['devise.mapping'] = Devise.mappings[:user]
	end

  let!(:creator) { create(:user, application: application.name, permissions: %w(TEST1)) }
	let!(:not_creator) { create(:user, application: application.name, permissions: %w(TEST1)) }
  let!(:invited_user) { create(:user, :with_future_invitation, created_by_id: creator.id, application: application.name, permissions: [{code: 'TEST1'}]) }
  let!(:expired_user) { create(:user, :with_expired_invitation, created_by_id: creator.id, application: application.name, permissions: %w(TEST1)) }

	# we are cheating in the factory girl by setting a map of raw/= to enc
	def get_raw_value_for(invitation_token)
		UserApplication.where(invitation_token: invitation_token).first.try(:invitation_token_raw) || invitation_token
	end
	def get_stored_value_for(invitation_token)
		invitation_token
	end

  describe "accept invitation" do
    let(:accept) do
      ->(token) {
        get :accept_invitation, token: get_raw_value_for(token)
      }
		end
		let(:accept_put) do
			->(token, password, confirmation) {
				put :accept_invitation_put, token: get_raw_value_for(token), user: {password: password, password_confirmation: confirmation}
			}
		end
		let(:accept_put_with_timestamp) do
			->(token, password, confirmation, timestamp) {
				put :accept_invitation_put, token: get_raw_value_for(token), user: {password: password, password_confirmation: confirmation}, initiated: timestamp
			}
		end
		let(:expire) do
      ->(application){
				application.update_attributes current_invitation_sent_at: 1.minutes.ago, invitation_expires_in: 0
 				application.expire
			}
    end
		let(:resubmit) do
			->(token) {
				get :resubmit_invitation_invitee, token: get_raw_value_for(token)
			}
		end
		let(:resend_request) do
			->(token) {
				get :resubmit_invitation_inviter, token: get_raw_value_for(token)
			}
		end
    context "valid invitation" do
			it "requires password without signing in" do
        accept.call(invited_user.user_applications.first.invitation_token)
        expect(response).to have_http_status(200)
        expect(response).to render_template('accept_invitation')
        expect(subject.current_user).to be_nil
      end

      it "allows a user to complete an invite, even if expired while on the page" do
				accept.call(invited_user.user_applications.first.invitation_token)

				expect(response).to have_http_status(200)
				expect(response).to render_template('accept_invitation')

        token = invited_user.user_applications.first.invitation_token
				expire[invited_user.user_applications.first]

				accept_put_with_timestamp[token, 'Password1!', 'Password1!', 2.minutes.ago.utc]
				expect(subject.current_user).to be
				expect(subject.current_user.application(application.name).invitation_status).to eq('complete')
				expect(subject.current_user.user_applications.first.invitation_token).to be_nil
				expect(subject.current_user.sign_in_count).to eq(1)
      end

			it "validate password set" do
				accept_put.call(invited_user.user_applications.first.invitation_token, 'Password1!', 'Password2!')
				expect(response).to have_http_status(200)
				expect(response).to render_template('accept_invitation')
				expect(subject.current_user).to be_nil
			end
			it "accepts password update and signs in" do
				accept_put.call(invited_user.user_applications.first.invitation_token, 'Password1!', 'Password1!')
				expect(subject.current_user).to be
				expect(subject.current_user.user_applications.first.invitation_status).to eq('complete')
				expect(subject.current_user.user_applications.first.invitation_token).to be_nil
				expect(subject.current_user.sign_in_count).to eq(1)
			end
		end
		context "invalid token" do
			it "redirects to login" do
				accept.call('bogustoken')
				expect(response).to redirect_to(new_user_session_path)
				expect(flash[:alert]).to be_present
			end
		end
		context "expired validation" do
			it "redirects to sign_in with flash" do
				accept.call(expired_user.user_applications.first.invitation_token)
				expect(response).to redirect_to(new_user_session_path)
				expect(flash[:alert]).to be_present
			end
			it "expects auth on resubmit" do
				old_token = expired_user.user_applications.first.invitation_token
				resend_request.call(expired_user.user_applications.first.invitation_token)
				expect(response).to redirect_to(new_user_session_path)
			end
			it "only allows resend for the inviter" do
				sign_in not_creator
				old_token = expired_user.user_applications.first.invitation_token
				resend_request.call(expired_user.user_applications.first.invitation_token)
				expect(response).to redirect_to(new_user_session_path)
				expect(flash[:alert]).to be_present
				expect(flash[:alert]).to match(/is only valid for the user/)
			end
			it "successfully re-invites if inviter is signed in and visits link" do
				sign_in creator
				resend_request.call(expired_user.user_applications.first.invitation_token)
				expect(response).to render_template('resubmit_invitation')
			end
			it "resubmits to inviter and redirects to sign in with flash on re-request invite" do
				user_application = expired_user.user_applications.first
				old_token = user_application.invitation_token

				expect_any_instance_of(UserApplication).to receive(:request_new_invite)

				resubmit.call(user_application.invitation_token)
				expect(response).to redirect_to(new_user_session_path)
				expect(flash[:notice]).to be_present
				expect(flash[:notice]).to match(/Your request to be re-invited/)
				expect(subject.current_user).to be_nil
				expired_user.reload
				expect(expired_user.user_applications.first.invitation_status).to eq('expired')
			end
		end
	end
end
