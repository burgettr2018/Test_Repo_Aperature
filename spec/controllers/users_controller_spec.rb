require "rails_helper"
require './spec/helpers/delayed_job_spec_helper.rb'

describe Api::V1::UsersController do
	include DelayedJobSpecHelper
	#include ActiveSupport::Testing::TimeHelpers

  let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application') }
  let!(:application_token) { create(:access_token, application: application) }

	let!(:application_with_postponed_invites) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application 3', postpone_all_invites: true) }
	let!(:application_with_postponed_invites_token) { create(:access_token, application: application_with_postponed_invites) }

	let!(:application_with_other_permission_access) { create(:oauth_application, :with_cross_app_permission_star, :with_user_manage_permission, name: 'Sample Application 2') }
	let!(:application_with_other_permission_access_token) { create(:access_token, application: application_with_other_permission_access) }

	before do
    allow(controller).to receive(:doorkeeper_token) { application_token }
	end

	describe "me" do
		let(:access_token) { nil }
		let!(:existing_user) { create(:user, application: application.name, permissions: %w(TEST1)) }
		subject { get :me, access_token: access_token }
		context "valid oauth bearer token" do
			let(:access_token) { Doorkeeper::AccessToken.find_or_create_for(nil, existing_user.id, 'public', 5.days, false).token }
			it "returns the info" do
				subject
				user_json = JSON.parse(response.body).with_indifferent_access
				expect(user_json[:username]).to eq(existing_user.username)
			end
		end
		context "expired oauth bearer token" do
			let(:access_token) { Doorkeeper::AccessToken.find_or_create_for(nil, existing_user.id, 'public', 1.second, false).token }
			it "returns 401" do
				Doorkeeper::AccessToken.where(token: access_token).first.update_columns(created_at: 1.day.ago)
				subject
				expect(response).to have_http_status(401)
			end
		end
		context "revoked oauth bearer token" do
			let(:access_token) { Doorkeeper::AccessToken.find_or_create_for(nil, existing_user.id, 'public', 5.days, false).token }
			it "returns 401" do
				Doorkeeper::AccessToken.where(token: access_token).first.revoke
				subject
				expect(response).to have_http_status(401)
			end
		end
		context "invalid oauth bearer token" do
			let(:access_token) { 'toodletoodledoo' }
			it "returns 401" do
				subject
				expect(response).to have_http_status(401)
			end
		end
		context "valid jwt token" do
			let(:access_token) { JwtHelper.from_access_token(Doorkeeper::AccessToken.find_or_create_for(nil, existing_user.id, 'public', 5.days, false)) }
			it "returns the info" do
				subject
				user_json = JSON.parse(response.body).with_indifferent_access
				expect(user_json[:username]).to eq(existing_user.username)
			end
		end
		context "expired jwt token" do
			let(:access_token) {
				token = Doorkeeper::AccessToken.find_or_create_for(nil, existing_user.id, 'public', 5.days, false)
				payload = {:sub => existing_user.id, :token => token.id}
				exp = (Time.now - 20.minutes).to_i
				key = JwtHelper.send(:key)
				JWT.encode payload.merge({exp: exp}), key, 'HS256'
			}
			it "returns 401" do
				subject
				expect(response).to have_http_status(401)
			end
		end
		context "invalid jwt token" do
			let(:access_token) { 'toodle.toodle.doo' }
			it "returns 401" do
				subject
				expect(response).to have_http_status(401)
			end
		end
	end

	describe "more invitation status tests" do
		let(:create_with_permissions) do
			->(user) {
				post :create_with_permissions, user
			}
		end
		context "no permissions" do
			let!(:user) { attributes_for(:user, application: application.name, user_permissions: []) }
			it "creates with status 'inactive'" do
				create_with_permissions.call(user)
				expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('inactive')
			end
			it "updates with status 'inactive'" do
				user2 = user.dup
				user2[:user_permissions] = [{
						code: 'TEST1'
																		}]
				create_with_permissions.call(user2)
				expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('invited')

				create_with_permissions.call(user)
				expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('inactive')
			end
		end
		context "with permissions" do
			let!(:user) { attributes_for(:user, application: application.name, user_permissions: [{code: 'TEST1'}]) }
			it "creates with status 'invited'" do
				create_with_permissions.call(user)
				expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('invited')
			end
		end
	end

	describe "get user" do
		let(:show) do
			->(user) {
				get :show, id: user.id
			}
		end
		let!(:existing_user) {
			create(:user, application: application.name, application_data: {data: 'data data data'}, permissions: %w(TEST1))
		}
		let!(:existing_user_with_other_app_permission) {
			create(:user, application: application.name,
                    application_data: {data: 'data data data'},
                    permissions: [{application: application.name, code: 'TEST1'}, {application: application_with_other_permission_access.name, code: 'TEST2'}])
		}

		it "shows basic info" do
			show.call(existing_user)
			user_json = JSON.parse(response.body).with_indifferent_access
			existing_user.reload
			expect(user_json[:type]).to eq('user')
			expect(user_json[:uid]).to eq(sprintf('%08d', existing_user.id))
			expect(user_json[:username]).to eq(existing_user.username)
			expect(user_json[:email]).to eq(existing_user.email)
			expect(user_json[:first_name]).to eq(existing_user.first_name)
			expect(user_json[:last_name]).to eq(existing_user.last_name)
			expect(user_json[:name]).to eq(existing_user.name)
			expect(user_json[:auth_status]).to eq(existing_user.application(application.name).invitation_status)
		end
		it "shows application_data merged in" do
			show.call(existing_user)
			user_json = JSON.parse(response.body).with_indifferent_access
			expect(user_json[application.name.underscore]).to include('data' => 'data data data')
		end

		context "without other app permission" do
			it "does not show other app permissions" do
				show.call(existing_user_with_other_app_permission)
				user_json = JSON.parse(response.body).with_indifferent_access
				expect(user_json[:permissions]).to include({application:application.name,permission:'TEST1',value:'*'})
				expect(user_json[:permissions]).not_to include({application:application_with_other_permission_access.name,permission:'TEST2',value:'*'})
			end
			it "does not merge other app data" do
				existing_user_with_other_app_permission.user_applications << create(:user_application, application: application_with_other_permission_access.name, application_data: {other_data: 'other other other'})
				existing_user_with_other_app_permission.reload
				show.call(existing_user_with_other_app_permission)
				user_json = JSON.parse(response.body).with_indifferent_access
				expect(user_json).to include(application.name.underscore => {'data' => 'data data data'})
				expect(user_json).not_to include(application_with_other_permission_access.name.underscore => {'other_data' => 'other other other'})
			end
		end
		context "with other app permission" do
			before do
				allow(controller).to receive(:doorkeeper_token) { application_with_other_permission_access_token }
			end
			it "does show other app permissions" do
				show.call(existing_user_with_other_app_permission)
				user_json = JSON.parse(response.body).with_indifferent_access
				expect(user_json[:permissions]).to include({application:application.name,permission:'TEST1',value:'*'})
				expect(user_json[:permissions]).to include({application:application_with_other_permission_access.name,permission:'TEST2',value:'*'})
			end
			it "does merge other app data" do
				existing_user_with_other_app_permission.application(application.name).update_attributes(application_data: {data: 'data data data'})
				existing_user_with_other_app_permission.user_applications << create(:user_application, application: application_with_other_permission_access.name)
				existing_user_with_other_app_permission.application(application_with_other_permission_access.name).update_attributes(application_data: {other_data: 'other other other'})
				existing_user_with_other_app_permission.reload
				show.call(existing_user_with_other_app_permission)
				user_json = JSON.parse(response.body).with_indifferent_access
				expect(user_json).to include(application.name.underscore => {'data' => 'data data data'})
				expect(user_json).to include(application_with_other_permission_access.name.underscore => {'other_data' => 'other other other'})
			end
		end


	end

	describe "invite user" do
		let(:create_with_permissions) do
			->(user) {
				post :create_with_permissions, user
			}
		end
		let!(:creator) { create(:user, application: application.name, permissions: %w(TEST1)) }
		context "new user" do
			let!(:user) { attributes_for(:user, created_by_email: creator.email, application: application.name, user_permissions: [{code: 'TEST1'}]) }
			it "creates a new user with invitation status 'invited'" do
				create_with_permissions.call(user)
				expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('invited')
			end
			it "creates a new user with invitation expiry in future" do
				create_with_permissions.call(user)
				new_user = User.find_by_email(user[:email]).application(application.name)
				expect(new_user.current_invitation_sent_at + new_user.invitation_expires_in).to be > Time.current
			end
			it "creates a invitation token" do
				create_with_permissions.call(user)
				new_user = User.find_by_email(user[:email]).application(application.name)
				expect(new_user.invitation_token).to be
			end
			it "sets invited by" do
				create_with_permissions.call(user)
				new_user = User.find_by_email(user[:email]).application(application.name)
				expect(new_user.invited_by_id).to eq(creator.id)
			end
			context "notifications" do
				before do
					ActionMailer::Base.deliveries = []
					clear_jobs
					Timecop.freeze(Time.local(1990))
				end

				after do
					Timecop.return
				end

				it "queues up and sends all 4 messages" do
					create_with_permissions.call(user)
					expect(job_count).to eq(1) # invitation mailer

					# the invite
					expect(perform_jobs).to eq [1, 0]
					expect(ActionMailer::Base.deliveries.count).to eq(1)
					mail = ActionMailer::Base.deliveries.last
					expect(mail.body.encoded).to match 'been invited'

					expiry_days = application.invitation_expiry_days
					Timecop.travel(Time.now + (expiry_days-2).days + 10.minutes)
					ActionMailer::Base.deliveries = []

					UserApplication.remind_invites
					expect(job_count).to eq(1) # reminder

					# the reminder
					expect(perform_jobs).to eq [1, 0]
					expect(job_count).to eq(0)
					expect(ActionMailer::Base.deliveries.count).to eq(1)
					mail = ActionMailer::Base.deliveries.last
					expect(mail.body.encoded).to match 'will expire'


					Timecop.travel(Time.now + 3.days)
					ActionMailer::Base.deliveries = []

					# the expiration
					UserApplication.expire_invites
					expect(job_count).to eq(2) # expiry notices

					expect(perform_jobs).to eq [2, 0]

					expect(ActionMailer::Base.deliveries.count).to eq(2)
					mail1 = ActionMailer::Base.deliveries[0]
					mail2 = ActionMailer::Base.deliveries[1]
					expect(mail1.body.encoded).to match 'has expired'
					expect(mail2.body.encoded).to match 'send a new'

					expect(mail1.body.encoded).not_to eq(mail2.body.encoded)
				end

				it "does not send reminder if already active" do
					create_with_permissions.call(user)

					# the invite
					expect(perform_jobs).to eq [1, 0]

					u = User.last
					u.last_sign_in_at = Time.now
					u.save!

					expiry_days = application.invitation_expiry_days
					Timecop.travel(Time.now + (expiry_days-2).days + 10.minutes)
					UserApplication.remind_invites

					expect(job_count).to eq(0)
				end

				it "does not send expiration if already active" do
					create_with_permissions.call(user)

					# the invite
					expect(perform_jobs).to eq [1, 0]

					u = User.last
					u.last_sign_in_at = Time.now
					u.save!

					expiry_days = application.invitation_expiry_days
					Timecop.travel(Time.now + (expiry_days).days + 10.minutes)
					UserApplication.expire_invites

					expect(job_count).to eq(0)
				end
			end
		end
		context "existing user expired" do
			let!(:existing_user) { create(:user, :with_expired_invitation, application: application.name, permissions: %w(TEST1)) }
			let!(:user) { attributes_for(:user, created_by_email: creator.email, email: existing_user.email, application: application.name, user_permissions: [{code: 'TEST1'}]) }
			it "current status is expired" do
				expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('expired')
			end
			it "updates with invitation status 're-invited'" do
				create_with_permissions.call(user)
				expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('re-invited')
			end
			it "updates with invitation expiry in future" do
				create_with_permissions.call(user)
				new_user = User.find_by_email(user[:email]).application(application.name)
				expect(new_user.current_invitation_sent_at + new_user.invitation_expires_in).to be > Time.current
				expect(new_user.first_invitation_sent_at).to be < new_user.current_invitation_sent_at
			end
			it "updates invited by" do
				expect(existing_user.application(application.name).invited_by_id).to be_nil
				create_with_permissions.call(user)
				new_user = User.find_by_email(user[:email]).application(application.name)
				expect(new_user.invited_by_id).to eq(creator.id)
			end
			it "updates with invitation token" do
				old_token = existing_user.application(application.name).invitation_token
				create_with_permissions.call(user)
				new_user = User.find_by_email(user[:email]).application(application.name)
				expect(new_user.invitation_token).to be
				expect(new_user.invitation_token).not_to eq(old_token)
			end
		end
	end

	describe "delete_user" do
		let(:delete_user) do
			->(user) {
				delete :delete_user, user
			}
		end

		let!(:existing_user) { create(:user, application: application.name, permissions: %w(TEST1 TEST2 TEST3)) }
		let!(:user) { attributes_for(:user, application: application.name) }

		context "with external_id" do
			let!(:existing_user) {
				response = super()
				response.user_applications.first.update_attributes(external_id: '1')
				response
			}
			context "when the user does not exist by external_id" do
				let!(:user) { super().merge(external_id: '2') }
				it "responds 204" do
					delete_user.call(user)
					expect(response).to have_http_status(204)
				end
				it "does nothing" do
					expect {delete_user.call(user)}.to_not change { User.count }
					expect {delete_user.call(user)}.to_not change { UserPermission.count }
				end
				context "even if user exists by email" do
					let!(:user) { super().merge(email: existing_user.email) }
					it "responds 204" do
						delete_user.call(user)
						expect(response).to have_http_status(204)
					end
					it "does nothing" do
						expect {delete_user.call(user)}.to_not change { User.count }
						expect {delete_user.call(user)}.to_not change { UserPermission.count }
					end
				end
			end
			context "when the user does exist by external_id" do
				let!(:user) { super().merge(external_id: '1') }
				it "responds 200" do
					delete_user.call(user)
					expect(response).to have_http_status(200)
				end
				it "does not delete user only permissions" do
					expect {delete_user.call(user)}.to change { UserPermission.count }
					expect {delete_user.call(user)}.to_not change { User.count }
				end
				it "removes user application record for current application" do
					delete_user.call(user)
					expect(existing_user.reload.user_applications.count).to eq(0)
				end
			end
		end
		context "with email" do
			context "when the user does not exist by email" do
				it "responds 204" do
					delete_user.call(user)
					expect(response).to have_http_status(204)
				end
				it "does nothing" do
					expect {delete_user.call(user)}.to_not change { User.count }
					expect {delete_user.call(user)}.to_not change { UserPermission.count }
				end
			end
			context "when the user does exist by email" do
				let!(:user) { super().merge(email: existing_user.email) }
				it "responds 200" do
					delete_user.call(user)
					expect(response).to have_http_status(200)
				end
				it "does not delete user only permissions" do
					expect {delete_user.call(user)}.to change { UserPermission.count }
					expect {delete_user.call(user)}.to_not change { User.count }
				end
				it "removes user application record for current application" do
					delete_user.call(user)
					expect(existing_user.reload.user_applications.count).to eq(0)
				end
			end
		end
	end

  describe "create_with_permissions" do
    describe "creating a new user" do
      let(:create_with_permissions) do
        ->(user) {
          post :create_with_permissions, user
        }
      end

			context "postponed invites" do
				context "specifically for contractor_portal" do
					let!(:contractor_portal) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'CONTRACTOR_PORTAL', postpone_all_invites: true) }
					let!(:contractor_portal_token) { create(:access_token, application: contractor_portal) }
					let!(:user) { attributes_for(:user, application: contractor_portal.name, contact: SecureRandom.uuid).merge(permissions: %w(TEST1 TEST2 TEST3).map{|p| {code: p}}) }
					before do
						allow(controller).to receive(:doorkeeper_token) { contractor_portal_token }
						ActionMailer::Base.deliveries = []
						clear_jobs
						Timecop.freeze(Time.local(1990))
					end
					after do
						Timecop.return
					end
					context "already expired" do
						let!(:user_guid) {SecureRandom.uuid}
						let!(:existing_user) {
							u = create(:user, :with_expired_invitation, application: contractor_portal.name, permissions: %w(TEST1 TEST2 TEST3).map{|p| {code: p}})
							u.user_applications.first.update_columns(external_id: user_guid)
							u
						}
						let!(:user) { attributes_for(:user, last_name: existing_user.last_name, application: contractor_portal.name, email: existing_user.email, contact: user_guid).merge(permissions: %w(TEST1 TEST2 TEST3).map{|p| {code: p}}) }
						it "current status is expired" do
							expect(User.find_by_email(user[:email]).application(contractor_portal.name).invitation_status).to eq('expired')
						end
						it "calls to MDMS" do
							create_with_permissions.call(user)
							new_user = User.find_by_email(user[:email])

							stub_request(:post, "#{ENV['MDMS_URL']}/api/v1/contractor/users").
									with(
											body: "{\"user\":{\"id\":#{new_user.id},\"type\":\"user\",\"guid\":\"#{new_user.guid}\",\"uid\":\"#{new_user.uid}\",\"external_id\":\"#{user[:contact]}\",\"username\":\"#{new_user.username}\",\"email\":\"#{new_user.email}\",\"first_name\":\"#{new_user.first_name}\",\"last_name\":\"#{new_user.last_name}\",\"name\":\"#{new_user.name}\",\"auth_status\":\"Expired\",\"permissions\":[{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST1\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST2\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST3\",\"value\":\"\"}],\"postpone_invite\":true}}",
											).
									to_return(status: 200, body: "", headers: {})
							expect(job_count).to eq(1) # rce helper mdms update
							expect(perform_jobs).to eq [1, 0]

							expect(User.find_by_email(user[:email]).application(contractor_portal.name).invitation_status).to eq('expired')
						end
						it "reinvites if MDMS calls back" do
							create_with_permissions.call(user)
							new_user = User.find_by_email(user[:email])

							stub_request(:post, "#{ENV['MDMS_URL']}/api/v1/contractor/users").
									with(
											body: "{\"user\":{\"id\":#{new_user.id},\"type\":\"user\",\"guid\":\"#{new_user.guid}\",\"uid\":\"#{new_user.uid}\",\"external_id\":\"#{user[:contact]}\",\"username\":\"#{new_user.username}\",\"email\":\"#{new_user.email}\",\"first_name\":\"#{new_user.first_name}\",\"last_name\":\"#{new_user.last_name}\",\"name\":\"#{new_user.name}\",\"auth_status\":\"Expired\",\"permissions\":[{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST1\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST2\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST3\",\"value\":\"\"}],\"postpone_invite\":true}}",
											).
									to_return(status: 200, body: "", headers: {})
							expect(job_count).to eq(1) # rce helper mdms update
							expect(perform_jobs).to eq [1, 0]

							create_with_permissions.call(user.merge(postpone_invite: false))
							new_user = User.find_by_email(user[:email])
							ua = new_user.application(contractor_portal.name)
							expect(ua.invitation_status).to eq('re-invited')
						end
					end
					it "calls out to rce helper" do
						create_with_permissions.call(user)
						new_user = User.find_by_email(user[:email])
						expect(new_user).to be
						expect(new_user.user_applications.count).to eq(1)
						ua = new_user.application(contractor_portal.name)
						expect(ua).to be
						expect(ua.invitation_status).to eq('inactive')
						expect(ua.invitation_token).not_to be
						expect(ua.external_id).to eq(user[:contact])

						stub_request(:post, "#{ENV['MDMS_URL']}/api/v1/contractor/users").
								with(
										body: "{\"user\":{\"id\":#{new_user.id},\"type\":\"user\",\"guid\":\"#{new_user.guid}\",\"uid\":\"#{new_user.uid}\",\"external_id\":\"#{user[:contact]}\",\"username\":\"#{new_user.username}\",\"email\":\"#{new_user.email}\",\"first_name\":\"#{new_user.first_name}\",\"last_name\":\"#{new_user.last_name}\",\"name\":\"#{new_user.name}\",\"auth_status\":\"Expired\",\"permissions\":[{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST1\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST2\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST3\",\"value\":\"\"}],\"postpone_invite\":true}}",
										).
								to_return(status: 200, body: "", headers: {})
						expect(job_count).to eq(1) # rce helper mdms update
						expect(perform_jobs).to eq [1, 0]

						create_with_permissions.call(user.merge(postpone_invite: false))
						new_user = User.find_by_email(user[:email])
						expect(new_user).to be
						expect(new_user.user_applications.count).to eq(1)
						ua = new_user.application(contractor_portal.name)
						expect(ua).to be
						expect(ua.postpone_invite).to be_falsey
						expect(ua.invitation_status).to eq('invited')
						expect(ua.invitation_token).to be
						expect(ua.external_id).to eq(user[:contact])

						stub_request(:post, "#{ENV['MDMS_URL']}/api/v1/contractor/users").
								with(
										body: "{\"user\":{\"id\":#{new_user.id},\"type\":\"user\",\"guid\":\"#{new_user.guid}\",\"uid\":\"#{new_user.uid}\",\"external_id\":\"#{user[:contact]}\",\"username\":\"#{new_user.username}\",\"email\":\"#{new_user.email}\",\"first_name\":\"#{new_user.first_name}\",\"last_name\":\"#{new_user.last_name}\",\"name\":\"#{new_user.name}\",\"invitation_expires_at\":\"#{(ua.current_invitation_sent_at + ua.invitation_expires_in).strftime('%Y-%m-%dT%H:%M:%S.%LZ')}\",\"auth_status\":\"Invited\",\"permissions\":[{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST1\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST2\",\"value\":\"\"},{\"application\":\"CONTRACTOR_PORTAL\",\"permission\":\"TEST3\",\"value\":\"\"}],\"postpone_invite\":false}}",
										).
								to_return(status: 200, body: "", headers: {})
						stub_request(:post, "#{ENV['RCE_BASE_URL']}#{ENV['RCE_USER_AUTH_STATUS_MESSAGE']}?accesstoken=#{ENV['RCE_ACCESS_TOKEN']}").
								with(
										body: "{\"contactGUID\":\"#{user[:contact]}\",\"authStatus\":\"Invited\",\"authLoginCount\":0,\"passcode\":\"#{ENV['RCE_PASSCODE']}\"}",
										).
								to_return(status: 200, body: File.read('spec/fixtures/rce_helper/update_user_auth_status_200.json'), headers: {'content-type': "application/json; charset=utf-8"})

						expect(job_count).to eq(3) # invitation mailer and rce helper auth/mdms update
						expect(perform_jobs).to eq [3, 0]

						# the invite
						expect(ActionMailer::Base.deliveries.count).to eq(1)
						mail = ActionMailer::Base.deliveries.last
						#custom template
						expect(mail.body.encoded).to match 'But have you tried it yet?'

					end
				end
				context "on request" do
					let!(:user) { attributes_for(:user, application: application.name).merge(permissions: %w(TEST1 TEST2 TEST3).map{|p| {code: p}}, postpone_invite: true) }
					it "creates the user but no invite" do
						create_with_permissions.call(user)
						new_user = User.find_by_email(user[:email])
						expect(new_user).to be
						expect(new_user.user_applications.count).to eq(1)
						ua = new_user.application(application.name)
						expect(ua).to be
						expect(ua.invitation_status).to eq('inactive')
						expect(ua.invitation_token).not_to be
					end
					it "called again for a postponed user sends invite" do
						create_with_permissions.call(user)

						create_with_permissions.call(user.merge(request_status: 'complete'))

						new_user = User.find_by_email(user[:email])
						expect(new_user).to be
						expect(new_user.user_applications.count).to eq(1)
						ua = new_user.application(application.name)
						expect(ua).to be
						expect(ua.invitation_status).to eq('invited')
						expect(ua.invitation_token).to be
					end
				end
				context "on application" do
					let!(:user) { attributes_for(:user, application: application_with_postponed_invites.name).merge(permissions: %w(TEST1 TEST2 TEST3).map{|p| {code: p}}) }
					before do
						allow(controller).to receive(:doorkeeper_token) { application_with_postponed_invites_token }
						ActionMailer::Base.deliveries = []
						clear_jobs
						Timecop.freeze(Time.local(1990))
					end
					after do
						Timecop.return
					end
					it "creates the user but no invite" do
						create_with_permissions.call(user)
						new_user = User.find_by_email(user[:email])
						expect(new_user).to be
						expect(new_user.user_applications.count).to eq(1)
						ua = new_user.application(application_with_postponed_invites.name)
						expect(ua).to be
						expect(ua.invitation_status).to eq('inactive')
						expect(ua.invitation_token).not_to be
					end
					it "called again for a postponed user sends invite" do
						create_with_permissions.call(user)

						create_with_permissions.call(user.merge(request_status: 'complete'))

						new_user = User.find_by_email(user[:email])
						expect(new_user).to be
						expect(new_user.user_applications.count).to eq(1)
						ua = new_user.application(application_with_postponed_invites.name)
						expect(ua).to be
						expect(ua.invitation_status).to eq('invited')
						expect(ua.invitation_token).to be
					end
					it "called again for a postponed user sends invite overrides app setting" do
						create_with_permissions.call(user)

						create_with_permissions.call(user.merge(postpone_invite: false))

						new_user = User.find_by_email(user[:email])
						expect(new_user).to be
						expect(new_user.user_applications.count).to eq(1)
						ua = new_user.application(application_with_postponed_invites.name)
						expect(ua).to be
						expect(ua.postpone_invite).to be_falsey
						expect(ua.invitation_status).to eq('invited')
						expect(ua.invitation_token).to be

						expect(job_count).to eq(1) # invitation mailer

						# the invite
						expect(perform_jobs).to eq [1, 0]
						expect(ActionMailer::Base.deliveries.count).to eq(1)
						mail = ActionMailer::Base.deliveries.last
						expect(mail.body.encoded).to match 'been invited'

					end
				end
			end

      context "when the user does not exist by email" do
        let!(:user) { attributes_for(:user, application: application.name).merge(permissions: %w(TEST1 TEST2 TEST3).map{|p| {code: p}}) }

				context "without externalid" do
          it "creates the user" do
            create_with_permissions.call(user)
						expect(User.find_by_email(user[:email])).to be
					end

					it "assigns a user_application record" do
            create_with_permissions.call(user)
						new_user = User.find_by_email(user[:email])
            expect(new_user.user_applications.count).to eq(1)
            expect(new_user.user_applications.first.oauth_application.name).to eq(application.name)
					end

					it "moves extra attributes into 'application_data' on user_application" do
						create_with_permissions.call(user.merge(something: 'to believe in'))
						new_user = User.find_by_email(user[:email])
						expect(new_user.user_applications.first.application_data).to include("something" => 'to believe in')
					end

					it "groups incoming permission records by code" do
						less_permissions_user = attributes_for(:user, user_permissions: [{code: 'TEST1', value: '1'}, {code: 'TEST1', value: '2'}, {code: 'TEST3', value: '3'}])
						create_with_permissions.call(less_permissions_user)
						new_user = User.find_by_email(less_permissions_user[:email])
						new_permission_ids = Hash[new_user.user_permissions.joins(:permission_type).order('permission_types.code asc').pluck(:code, :value)]
						expect(new_permission_ids).to eq({'TEST1' => '1,2', 'TEST3' => '3'})
					end

					it "removes duplicates in grouped codes" do
						less_permissions_user = attributes_for(:user, user_permissions: [{code: 'TEST1', value: '1'}, {code: 'TEST1', value: '2'}, {code: 'TEST1', value: '2'}, {code: 'TEST3', value: '3'}])
						create_with_permissions.call(less_permissions_user)
						new_user = User.find_by_email(less_permissions_user[:email])
						new_permission_ids = Hash[new_user.user_permissions.joins(:permission_type).order('permission_types.code asc').pluck(:code, :value)]
						expect(new_permission_ids).to eq({'TEST1' => '1,2', 'TEST3' => '3'})
					end
				end

				context "with external_id" do
					let!(:user) { super().merge(external_id: '1') }
					it "creates the user" do
						create_with_permissions.call(user)
						expect(User.find_by_email(user[:email])).to be
					end
					it "assigns a user_application record with external_id" do
						create_with_permissions.call(user)
						new_user = User.find_by_email(user[:email])
						expect(new_user.user_applications.count).to eq(1)
						expect(new_user.user_applications.joins(:oauth_application).where(oauth_applications: { name: application.name }, external_id: user[:external_id]).first).to be
					end

					context "matching existing internal id" do
						let(:existing_user_invited) {
							response = create(:user, :with_invitation_token, application: application.name, permissions: %w(TEST1 TEST2 TEST3))
							response.user_applications.first.update_attributes(external_id: '1')
							response
						}
						let(:existing_user_complete) {
							response = create(:user, application: application.name, permissions: %w(TEST1 TEST2 TEST3))
							response.user_applications.first.update_attributes(external_id: '1')
							response
						}
						let(:existing_user_expired) {
							response = create(:user, application: application.name, permissions: %w(TEST1 TEST2 TEST3))
							response.user_applications.first.update_attributes(external_id: '1', invitation_status: 'expired')
							response
						}
						it "updates the existing email if new email doesn't exist" do
							expect(User.where(email: existing_user_invited.email).count).to eq(1)
							create_with_permissions.call(user)
							expect(User.where(email: user[:email]).count).to eq(1)
							expect(User.where(email: existing_user_invited.email).count).to eq(0)
						end
						it "invites again if in invited status" do
							old_app = existing_user_invited.application(application.name)
							old_token = old_app.invitation_token
							expect(old_app.invitation_status).to eq('invited')
							expect(old_token).to be
							create_with_permissions.call(user)
							new_user = User.find_by_email(user[:email]).application(application.name)
							expect(new_user.invitation_token).to be
							expect(new_user.invitation_token).not_to eq(old_token)
						end
						it "invites again if in expired status" do
							old_app = existing_user_expired.application(application.name)
							expect(old_app.invitation_status).to eq('expired')
							create_with_permissions.call(user)
							new_user = User.find_by_email(user[:email]).application(application.name)
							expect(new_user.invitation_token).to be
						end
						it "doesn't invite again if not in invited status" do
							old_app = existing_user_complete.application(application.name)
							old_token = old_app.invitation_token
							expect(old_app.invitation_status).to eq('complete')
							expect(old_token).not_to be
							create_with_permissions.call(user)
							new_user = User.find_by_email(user[:email]).application(application.name)
							expect(new_user.invitation_token).not_to be
						end
						context "new email already exists" do
							let!(:new_user) {
								User.create!(email: user[:email],
														 password: 'password',
														 skip_password_complexity_validation: true)
							}
							it "throws if existing user they already exist for app with a different external id" do
								new_user.user_applications << UserApplication.new(oauth_application: application, external_id: '2')
								expect(User.where(email: existing_user_complete.email).count).to eq(1)
								expect(User.where(email: new_user.email).count).to eq(1)
								create_with_permissions.call(user)
								expect(response).not_to be_success
								expect(User.where(email: user[:email]).count).to eq(1)
								expect(User.where(email: existing_user_complete.email).count).to eq(1)
							end
							it "joins the existing user if adding permissions for this app" do
								expect(User.where(email: existing_user_complete.email).count).to eq(1)
								expect(User.where(email: new_user.email).count).to eq(1)
								less_permissions_user = user.merge(user_permissions: [{code: 'TEST1', value: '1'}, {code: 'TEST1', value: '2'}, {code: 'TEST3', value: '3'}])
								create_with_permissions.call(less_permissions_user)
								expect(response).to be_success
								expect(User.where(email: user[:email]).count).to eq(1)
								expect(User.where(email: existing_user_complete.email).count).to eq(1)
								expect(User.where(email: existing_user_complete.email).first.user_applications.first).to be_nil
								expect(User.where(email: user[:email]).first.user_applications.first.external_id).to eq('1')
								#and invites
								expect(User.find_by_email(user[:email]).application(application.name).invitation_status).to eq('invited')
							end
						end
					end
				end
			end

			context "when the user does exist by email" do
				let!(:existing_other_app_user) { create(:user, application: 'Other Application', permissions: %w(TEST1 TEST2 TEST3)) }
        let!(:existing_user) { create(:user, application: application.name, permissions: %w(TEST1 TEST2 TEST3)) }
        let!(:user) { attributes_for(:user, email: existing_user.email) }

        context "without externalid" do
          it "updates the existing user" do
            create_with_permissions.call(user)
            expect(User.joins(user_applications: [:oauth_application]).where(oauth_applications: {name: application.name}).count).to eq(1)
						expect(User.find_by_email(existing_user.email).last_name).to eq(user[:last_name])
					end

					it "adds the user application if not exist" do
						create_with_permissions.call(user)
						expect(User.joins(user_applications: [:oauth_application]).where(oauth_applications: {name: application.name}).count).to eq(1)
						expect(User.find_by_email(existing_user.email).last_name).to eq(user[:last_name])
					end

					it "adds the user application to existing collection" do
						create_with_permissions.call(user.merge(email: existing_other_app_user.email))
						expect(User.find_by_email(existing_other_app_user.email).user_applications.count).to eq(2)
					end

					it "removes the existing permissions if none sent" do
						create_with_permissions.call(user)
						expect(existing_user.user_permissions.count).to eq(0)
					end
					it "removes specific permissions if less sent" do
						less_permissions_user = attributes_for(:user, email: existing_user.email, user_permissions: [{code: 'TEST1', value: '*'}, {code: 'TEST3', value: '*'}])
						create_with_permissions.call(less_permissions_user)
						expect(existing_user.user_permissions.joins(:permission_type).pluck(:code)).to eq(%w(TEST1 TEST3))
					end
					it "updates existing permission records instead of creating new" do
						less_permissions_user = attributes_for(:user, email: existing_user.email, user_permissions: [{code: 'TEST1', value: '*'}, {code: 'TEST2', value: '*'}, {code: 'TEST3', value: '*'}])
						existing_permission_ids = Hash[existing_user.user_permissions.order(id: :asc).pluck(:id, :value)]
						create_with_permissions.call(less_permissions_user)
						new_permission_ids = Hash[existing_user.user_permissions.order(id: :asc).pluck(:id, :value)]
						expect(existing_permission_ids).to eq(new_permission_ids)
					end

				end
				context "with external_id" do
					let!(:existing_other_app_user) {
						response = super()
						response.user_applications.first.update_attributes(external_id: '1')
						response
					}
					let!(:existing_user) {
						response = super()
						response.user_applications.first.update_attributes(external_id: '1')
						response
					}
					let!(:user) { super().merge(external_id: '1') }
					it "updates the user" do
						create_with_permissions.call(user)
						expect(User.find_by_email(existing_user.email).last_name).to eq(user[:last_name])
					end

					context "but incoming user email already exists in another app" do
						let!(:user) { super().merge(email: existing_other_app_user.email) }
						it "succeeds because it's a different app" do
							create_with_permissions.call(user)
							expect(response).to have_http_status(200)
						end
					end

					context "but incoming user email already exists in same app" do
						let!(:user) { super().merge(email: existing_user.email, external_id: '2') }
						it "fails" do
							create_with_permissions.call(user)
							expect(response).to have_http_status(400)
							expect(User.find_by_email(existing_user.email).user_applications.first.external_id).to eq('1')
						end

						context "unless external_id same" do
							let!(:existing_user) {
								response = super()
								response.user_applications.first.update_attributes(external_id: '2')
								response
							}
							it "succeeds" do
								create_with_permissions.call(user)
								expect(response).to have_http_status(200)
							end
						end
						context "or existing external_id nil" do
							let!(:existing_user) {
								response = super()
								response.user_applications.first.update_attributes(external_id: nil)
								response
							}
							it "succeeds" do
								create_with_permissions.call(user)
								expect(response).to have_http_status(200)
								expect(User.find_by_email(existing_user.email).user_applications.first.external_id).to eq('2')
							end
						end
					end

				end
			end
    end
  end
end
