require "rails_helper"
require "savon/mock/spec_helper"

describe TransactionalPortalHelper do
	# include the helper module
	include Savon::SpecHelper

	# set Savon in and out of mock mode
	before(:all) {
		savon.mock!
		#WebMock.allow_net_connect!
	}
	after(:all)  {
		savon.unmock!
		#WebMock.disable_net_connect!
	}

	# describe "get ad user", pending: "Refactor the wazjub for easier frobbing" do
	# 	context "missing user" do
	# 		it "returns nil" do
	# 			message = { user_name: 'doodz' }
	# 			fixture = File.read('spec/fixtures/transactional_portal_helper/get_ad_user/missing.xml')
	#
	# 			savon.expects(:get_user_details_by_user_name).with(message: message).returns(fixture)
	#
	# 			response = TransactionalPortalHelper.get_ad_user(message[:user_name])
	#
	# 			expect(response).to be_nil
	# 		end
	# 	end
	# 	context "valid user" do
	# 		it "returns details" do
	# 			message = { user_name: 'doodz' }
	# 			fixture = File.read('spec/fixtures/transactional_portal_helper/get_ad_user/success.xml')
	#
	# 			savon.expects(:get_user_details_by_user_name).with(message: message).returns(fixture)
	#
	# 			response = TransactionalPortalHelper.get_ad_user(message[:user_name])
	#
	# 			expect(response).to eq({
	# 																 email_address: 'doodz@doodz.com',
	# 																 first_name: 'first',
	# 																 last_name: 'last',
	# 																 user_account_control: '66048',
	# 																 user_name: 'doodz',
	# 																 user_account_control_desc: 'NORMAL_ACCOUNT|DONT_EXPIRE_PASSWORD'
	# 														 })
	# 		end
	# 	end
	# end
	# describe "add_or_enable_ad_user", pending: "Refactor the wazjub for easier frobbing" do
	# 	it "calls appropriate and returns success" do
	# 		message = { user_name: 'doodz', first_name: 'first', last_name: 'last', email_address: 'doodz@doodz.com', password: 'secret' }
	# 		fixture = File.read('spec/fixtures/transactional_portal_helper/add_or_enable_ad_user/success.xml')
	#
	# 		savon.expects(:add_or_enable_user).with(message: message).returns(fixture)
	#
	# 		response = TransactionalPortalHelper.add_or_enable_ad_user(message[:user_name], message[:email_address], message[:first_name], message[:last_name], message[:password])
	#
	# 		expect(response).to eq(true)
	# 	end
	# 	it "handles failures" do
	# 		message = { user_name: 'doodz', first_name: 'first', last_name: 'last', email_address: 'doodz@doodz.com', password: 'secret' }
	# 		fixture = File.read('spec/fixtures/transactional_portal_helper/add_or_enable_ad_user/soap_fault.xml')
	# 		response = { code: 500, headers: {}, body: fixture }
	#
	# 		savon.expects(:add_or_enable_user).with(message: message).returns(response)
	#
	# 		expect{TransactionalPortalHelper.add_or_enable_ad_user(
	# 				message[:user_name],
	# 				message[:email_address],
	# 				message[:first_name],
	# 				message[:last_name],
	# 				message[:password])
	# 		}.to raise_error
	# 	end
	# end
	# describe "disable ad user", pending: "Refactor the wazjub for easier frobbing" do
	# 	it "calls appropriate and returns success" do
	# 		message = { user_name: 'doodz' }
	# 		fixture = File.read('spec/fixtures/transactional_portal_helper/disable_ad_user/success.xml')
	#
	# 		savon.expects(:disable_user).with(message: message).returns(fixture)
	#
	# 		response = TransactionalPortalHelper.disable_ad_user(message[:user_name])
	#
	# 		expect(response).to eq(true)
	# 	end
	# 	it "handles failures" do
	# 		message = { user_name: 'doodz' }
	# 		fixture = File.read('spec/fixtures/transactional_portal_helper/disable_ad_user/soap_fault.xml')
	# 		response = { code: 500, headers: {}, body: fixture }
	#
	# 		savon.expects(:add_or_enable_user).with(message: message).returns(response)
	#
	# 		expect{TransactionalPortalHelper.disable_ad_user(message[:user_name])}.to raise_error
	# 	end
	# end
	# describe "get ad user email by username", pending: "Refactor the wazjub for easier frobbing" do
	# 	context "with existing user" do
	# 		it "calls the expected method" do
	# 			message = { user_id: 'doodz' }
	# 			fixture = File.read('spec/fixtures/transactional_portal_helper/get_ad_user_email_by_user_id/success.xml')
	#
	# 			savon.expects(:get_ad_user_email_by_user_id).with(message: message).returns(fixture)
	#
	# 			response = TransactionalPortalHelper.get_ad_user_email_by_user_id(message[:user_id])
	#
	# 			expect(response).to eq('doodz@doodz.com')
	# 		end
	# 	end
	# 	context "with missing user" do
	# 		it "calls the expected method" do
	# 			message = { user_id: 'doodz' }
	# 			fixture = File.read('spec/fixtures/transactional_portal_helper/get_ad_user_email_by_user_id/missing.xml')
	#
	# 			savon.expects(:get_ad_user_email_by_user_id).with(message: message).returns(fixture)
	#
	# 			response = TransactionalPortalHelper.get_ad_user_email_by_user_id(message[:user_id])
	#
	# 			expect(response).to be_nil
	# 		end
	# 	end
	# 	context "with fault" do
	# 		it "calls the expected method" do
	# 			message = { user_id: 'doodz' }
	# 			fixture = File.read('spec/fixtures/transactional_portal_helper/get_ad_user_email_by_user_id/soap_fault.xml')
	# 			response = { code: 500, headers: {}, body: fixture }
	#
	# 			savon.expects(:get_ad_user_email_by_user_id).with(message: message).returns(response)
	#
	# 			expect{TransactionalPortalHelper.get_ad_user_email_by_user_id(message[:user_id])}.to raise_error
	# 		end
	# 	end
	# end
	describe "get ad user by email" do
		context "with existing user" do
			it "calls the expected method" do
				message = { email_address: 'doodz@doodz.com' }
				fixture = File.read('spec/fixtures/transactional_portal_helper/get_user_details_by_email_address/success.xml')

				savon.expects(:get_user_details_by_email_address).with(message: message).returns(fixture)

				response = TransactionalPortalHelper.get_ad_user_by_email(message[:email_address])

				expect(response.try(:[], :user_name)).to eq('doodz')
			end
		end
		context "with missing user" do
			it "calls the expected method" do
				message = { email_address: 'doodz@doodz.com' }
				fixture = File.read('spec/fixtures/transactional_portal_helper/get_user_details_by_email_address/missing.xml')

				savon.expects(:get_user_details_by_email_address).with(message: message).returns(fixture)

				response = TransactionalPortalHelper.get_ad_user_by_email(message[:email_address])

				expect(response).to be_nil
			end
		end
	end
end
