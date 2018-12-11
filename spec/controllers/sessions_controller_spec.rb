#<samlp:AuthnRequest AssertionConsumerServiceURL='http://localhost:3000/saml/acs' Destination='http://localhost:3002/users/saml/sso' ID='_7cc9983c-57db-40b2-9fd8-a4863c1c7637' IssueInstant='2017-08-09T19:35:09Z' Version='2.0' xmlns:saml='urn:oasis:names:tc:SAML:2.0:assertion' xmlns:samlp='urn:oasis:names:tc:SAML:2.0:protocol'><saml:Issuer>http://localhost:3000/saml/metadata</saml:Issuer><samlp:NameIDPolicy AllowCreate='true' Format='urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress'/></samlp:AuthnRequest>
require "rails_helper"

describe SessionsController do
	let!(:application) { create(:oauth_application, :with_user_manage_permission, :with_invitation_period, name: 'Sample Application', saml_acs: 'http://validacs.com/') }
	let!(:estore) { create(:oauth_application, name: 'estore', sso_token: 'estore') }

	before do
		request.env['devise.mapping'] = Devise.mappings[:user]
		stub_request(:post, ENV['UMS_USER_SERVICE_WSDL'].gsub(/\?wsdl$/,'')).
				with(headers: { 'Soapaction'=>'"http://tempuri.org/IUserService/GetUserDetailsByEmailAddress"'}).
				to_return(status: 200, body: File.read('spec/fixtures/transactional_portal_helper/get_user_details_by_email_address/success.xml'), headers: {})
	end

	let!(:creator) { create(:user, application: application.name, permissions: %w(TEST1)) }
	let!(:invited_user) { create(:user, :with_future_invitation, created_by_id: creator.id, application: application.name, permissions: [{code: 'TEST1'}]) }
	let!(:expired_user) { create(:user, :with_expired_invitation, application: application.name, permissions: %w(TEST1)) }
	let!(:inactive_user) { create(:user, application: application.name, permissions: []) }
	let!(:valid_account) { SecureRandom.uuid }
	let(:location) { SecureRandom.uuid }
	let!(:valid_location) { SecureRandom.uuid }
	let!(:invalid_location) { SecureRandom.uuid }
	let(:active_user) {
		user = create(:user, application: 'CONTRACTOR_PORTAL', permissions: active_user_permissions)
		create(:rce_virtual_adfs_user, user: user, location_guid: valid_location)
		user
	}
	let(:active_user_permissions) { [] }

	def get_permissions(hash)
		hash.map{
				|k,v|
			{
					"application": "CONTRACTOR_PORTAL",
					"code": k.to_s.upcase,
					"value": v.to_s
			}
		}
	end

	describe "saml" do
		let(:saml) do
			->(acs) {
				get :saml, SAMLRequest: create(:saml_request, acs: acs)
			}
		end
		context "invalid acs" do
			it "rejects with flash" do
				saml.call('http://invalidacs.com/')
				expect(flash[:alert]).to be_present
				expect(flash[:alert]).to match('Session cannot be established')
			end
		end
		context "valid acs" do
			it "keeps on going" do
				saml.call(application.saml_acs)
				expect(flash[:alert]).to be_nil
			end
		end
	end
	describe "create" do
		let (:session_create) do
			->(user, acs=nil) {
				post :create, user: user.slice(:login, :password), SAMLRequest: saml_request.call(user, acs)
			}
		end
		let (:saml_request) do
			->(user, acs=nil) {
				nil
			}
		end
		context "with saml" do
			let (:saml_request) do
				->(user, acs=nil) {
					create(:saml_request, acs: acs)
				}
			end
			context "invalid acs" do
				it "rejects with flash" do
					session_create.call(invited_user, 'http://invalidacs.com/')
					expect(flash[:alert]).to be_present
					expect(flash[:alert]).to match('Session cannot be established')
				end
			end
			context "valid acs" do
				it "keeps on going for valid user" do
					session_create.call(invited_user, application.saml_acs)
					expect(flash[:alert]).to be_nil
					expect(response).to render_template('sso')
					expect(invited_user.log_in_count).to eq(1)
					expect(invited_user.password_changed_count).to eq(0)
					expect(invited_user.devise_log_histories.first.devise_action).to eq('signed_in')
					expect(invited_user.devise_log_histories.first.date.to_date).to eq(Date.current)
				end
				it "blocks for inactive user" do
					session_create.call(inactive_user, application.saml_acs)
					expect(flash[:alert]).to be_present
					expect(flash[:alert]).to match('denied')
				end
			end
		end
	end
	describe "estore" do#, pending: "Refactor the wazjub for easier frobbing" do
		subject {
			get :estore, location: location
		}
		context "logged in already" do
			before(:each) do
				sign_in active_user, scope: :user
			end
			context "with estore access" do
				let(:active_user_permissions) {
					get_permissions(access_estore: true)
				}
				context "global user" do
					let(:active_user_permissions) {
						super() + get_permissions(level: 'GLOBAL', account: valid_account)
					}
					context "valid location", pending: "figure out cross-db access in unit tests" do
						let(:location) { valid_location }
						it { is_expected.to render_template('sso') }
					end
					context "invalid location" do
						let(:location) { invalid_location }
						it { is_expected.to redirect_to(new_user_session_path) }
					end
				end
				context "location user" do
					let(:active_user_permissions) {
						super() + get_permissions(level: 'LOCATION', account: valid_account, location: valid_location)
					}
					context "valid location", pending: "figure out cross-db access in unit tests" do
						let(:location) { valid_location }
						it { is_expected.to render_template('sso') }
					end
					context "invalid location" do
						let(:location) { invalid_location }
						it { is_expected.to redirect_to(new_user_session_path) }
					end
				end
			end
		end
		context "not logged in" do
			it { is_expected.to redirect_to(new_user_session_path) }
			it {
				subject
				expect(controller.session[:return_to]).to eq(estore_sso_path(location))
			}
		end
	end
end
