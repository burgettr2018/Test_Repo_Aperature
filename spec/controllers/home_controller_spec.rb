require "rails_helper"

describe HomeController do

	before do
		request.env['devise.mapping'] = Devise.mappings[:user]
	end

	let!(:cpi) { create(:oauth_application, name: 'CPI', sso_token: 'cpi', application_uri: '/CPI_URI') }
	let!(:mdms) { create(:oauth_application, name: 'MDMS', sso_token: 'mdms', application_uri: '/MDMS_URI') }
	let!(:contractor_portal) { create(:oauth_application, name: 'CONTRACTOR_PORTAL', sso_token: 'contractor_portal', application_uri: '/CONTRACTOR_PORTAL_URI') }
	let!(:oc_com) { create(:oauth_application, name: 'OC_COM', sso_token: 'oc_com', application_uri: '/OC_COM_URI') }
	let!(:customer_portal) { create(:oauth_application, name: 'CUSTOMER_PORTAL', sso_token: 'customer_portal', application_uri: '/OC_COM_URI/customerportal') }

	let(:application) { contractor_portal }
	let(:admin) { false }
	let(:active_user) { create(:user, application: application, permissions: active_user_permissions, admin: admin ) }
	let(:active_user_permissions) { [] }

	subject {
		get :index
	}

	context "logged in" do
		before(:each) do
			sign_in active_user, scope: :user
		end

		context "multiple applications" do
			let(:active_user_permissions) { [{application: 'CONTRACTOR_PORTAL', code: 'ACCOUNT', value: 'blah'}, {application: 'CPI', code: 'CPI_PROCESSOR', value: 'blah'}] }
			context "non-admin" do
				it { is_expected.to render_template('home/index') }
			end
			context "admin" do
				let(:admin) { true }
				it { is_expected.to render_template('home/index') }
			end
		end

		context "single application" do
			context "regular CONTRACTOR_PORTAL user" do
				let(:active_user_permissions) { [{application: 'CONTRACTOR_PORTAL', code: 'ACCOUNT', value: 'blah'}] }
				context "non-admin" do
					it { is_expected.to redirect_to('/CONTRACTOR_PORTAL_URI') }
				end
				context "admin" do
					let(:admin) { true }
					it { is_expected.to render_template('home/index') }
				end
			end
			context "user with CONTRACTOR_PORTAL impersonate only" do
				let(:active_user_permissions) { [{application: 'CONTRACTOR_PORTAL', code: 'IMPERSONATE'}] }
				context "non-admin" do
					it { is_expected.to redirect_to(users_impersonate_path) }
				end
				context "admin" do
					let(:admin) { true }
					it { is_expected.to render_template('home/index') }
				end
			end

			context "user with customer portal permissions only" do
				let(:application) { mdms }
				let(:active_user_permissions) { [{application: 'MDMS', code: 'OA_SHIPTO'}, {application: 'MDMS', code: 'OA_PAYER'}, {application: 'MDMS', code: 'OA_SOLDTO'}] }
				context "admin" do
					it { is_expected.to redirect_to('/OC_COM_URI/customerportal') }
				end
				context "admin" do
					let(:admin) { true }
					it { is_expected.to render_template('home/index') }
				end
			end
			context "user with cross app customer portal permissions only" do
				let(:application) { mdms }
				let(:active_user_permissions) { [{application: 'MDMS', code: 'OA_SHIPTO'}, {application: 'MDMS', code: 'OA_PAYER'}, {application: 'MDMS', code: 'OA_SOLDTO'}] }
				let(:active_user) {
					user = create(:user, application: application, permissions: active_user_permissions, admin: admin)
					user.user_applications << create(:user_application, application: customer_portal)
					user.user_permissions << create(:user_permission, application: 'CUSTOMER_PORTAL', code: 'OA_CSB')
					user
				}
				context "non-admin" do
					it { is_expected.to redirect_to('/OC_COM_URI/customerportal') }
				end
				context "admin" do
					let(:admin) { true }
					it { is_expected.to render_template('home/index') }
				end
			end
		end
	end
	context "not logged in" do
		it { is_expected.to redirect_to new_user_session_path }
	end
end