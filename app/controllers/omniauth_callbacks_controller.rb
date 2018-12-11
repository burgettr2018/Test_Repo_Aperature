class AuthMock < Hash
	def initialize
		super
	end

	def provider
		'oktaabc'
	end

end

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include OktaCookieHelper

	 skip_before_action :verify_authenticity_token

	 def test_abc_okta

     #this is only for admin testing ;)
     raise ActionController::RoutingError.new('Not Found') if current_user.blank? || !current_user.admin

     #Mock out what the okta request would look like from abcsupply, you can set values via params else will default to Rick
     request.env["omniauth.auth"] = AuthMock.new
		 request.env["omniauth.auth"]['extra'] = {
				 'raw_info' => {
						 'Email' =>  params[:email]||'rick.byington@owenscorning.com',
						 'FirstName' =>  params[:firstname]||'Rick',
						 'LastName' =>  params[:lastname]||'Byington',
						 'Username' => params[:email]||'rick.byington@owenscorning.com',
						 'Location' => params[:location]||'002'
				 }
		 }

		 oktaabc

	 end

	 def oktaabc

     provider = SamlIdentityProvider.where(token: 'oktaabc').first
     @user = fetch_or_create_user(provider)
     sign_in(:user,@user)

		 set_signed_in_with_oktaabc_cookie

		 AbcAuditLog.create!(message:"SSO User Login",data:@user.provider_metadata)

     #if user has 'ABC Override don't rewrite their permissions, assuming they have been manually setup and send over to portal
		if @user.has_permission?('MDMS','ABC_OVERRIDE')
			AbcAuditLog.create!(message:"User #{@user.email} has ABC_OVERRIDE, redirecting",data:@user.provider_metadata,log_type:'redirect')

			#We go here because it will force the currently logged in user on customer portal to logout and login as the user we signed in here (all without the user knowing)
			return redirect_to "#{ENV['UMS_OC_URL']}/users/login?return_url=%2Fcustomerportal%2Forder-status"
		end

		begin
      #OK, lets see what okta sent use for a 'location' we use this to lookup what permissions the user should have
      #IF we find locations permisions, set them on the user and redirect to the portal
			location = @user.provider_metadata.try(:[], 'Location')
      location =  location.first if !location.blank? && location.kind_of?(Array)
			location_permissions = nil
			location_permissions = AbcLocationPermission.where(location_number: location.to_i.to_s) if !location.blank?


			if !location_permissions.blank?
				permissions = location_permissions.map{|a|  {'permission'=>a[:permission], 'application'=>'MDMS', 'value'=>a[:value]}}
        permissions <<  {'permission'=>'OA_BMG', 'application'=>'MDMS', 'value'=>''}
				@user.update_permissions_from_hash(permissions, @user, OauthApplication.find_by_name('MDMS'))
				AbcAuditLog.create!(message:"successfully updated permissions #{permissions.to_s}",data:@user.provider_metadata,log_type:'success')

				#We go here because it will force the currently logged in user on customer portal to logout and login as the user we signed in here (all without the user knowing)
				return redirect_to "#{ENV['UMS_OC_URL']}/users/login?return_url=%2Fcustomerportal%2Forder-status"
      else
        #no permission were found, this happens for ABC Branches that haven't been setup, send an email to helpdesk and
        #so the user the 'account-not-found' screen
				AbcAuditLog.create!(message:"Location not found",data:@user.provider_metadata,log_type:'notfound')
				ApplicationMailer.abc_no_account(@user).deliver_now
				return redirect_to '/account-not-found'
			end
    rescue => e
      #Yikes, something didn't go as planned, log the error then raise it (the user will see a 500 error ;( )
			AbcAuditLog.create!(message:"Error #{e.message}",data:@user.provider_metadata,log_type:'error')
			logger.error "Error during processing: #{$!}"
			logger.error "Backtrace:\n\t#{e.backtrace.join("\n\t")}"
			notify_airbrake(e)
      ApplicationMailer.abc_sso_error(@user,e).deliver_now
      raise e
		end

	 end


	 def action_missing(methId)
 		provider = SamlIdentityProvider.where(token: methId).first
 		if provider.nil?
 			raise NoMethodError
 		else
 			user = fetch_or_create_user(provider)

      if provider.is_test_mode.to_b
        @title = "#{provider.name} SSO"
        @message = "You have successfully authenticated via #{provider.name}. This provider is configured for test mode, meaning only the claim info is output here:"
        @sso_details = user.provider_metadata
        render 'devise/sessions/sso_placeholder' and return
      end


      auth_info = request.env["omniauth.auth"]
 			set_signed_in_with_okta_cookie if auth_info.provider == "okta"


 			# If you are using confirmable and the provider(s) you use validate emails,
 			# uncomment the line below to skip the confirmation emails.
 			# user.skip_confirmation!

      if !cookies[:SAMLRequest].blank?
        sign_in(:user,user)
        redirect_to idp_saml_sso_path
      else
        sign_in_and_redirect user, :event => :authentication # this will throw if @user is not activated
 			  set_flash_message(:notice, :success, :kind => provider.name) if is_navigational_format?
      end
 		end
 	end

	 def failure
 		redirect_to root_path
 	end

	private


	 def fetch_or_create_user(provider)
 		auth_info = request.env["omniauth.auth"]

 		external_email = auth_info['extra']['raw_info']['Email']
 		external_first_name = auth_info['extra']['raw_info']['FirstName']
 		external_last_name = auth_info['extra']['raw_info']['LastName']
 		external_user_name = auth_info['extra']['raw_info']['Username']
 		external_metadata = auth_info['extra']['raw_info'].to_h.except!('fingerprint')

		#external_email = "rick@abctest.com" if external_email == 'rick.byington@owenscorning.com'
		#external_email = "kristen@abctest.com" if external_email == 'kristen.brown@owenscorning.com'


		user = User.where(provider: auth_info.provider).find_for_authentication(email: external_email)
    username = external_user_name #"#{auth_info.provider}_#{external_user_name}"
 		if user.present?
 			# user exists for provider, just check if attributes need updated
 			if user.first_name != external_first_name || user.last_name != external_last_name || user.username != external_user_name || !HashDiff.diff(external_metadata, user.provider_metadata).blank?
       	user.first_name = external_first_name
 				   user.last_name = external_last_name
 				   user.username = username
 				   user.provider_metadata = external_metadata
 				   user.skip_password_complexity_validation = true
 				   user.save!
 			end

 			set_signed_in_with_okta_cookie if auth_info.provider == "okta"
 		else
 			# user does not exist by provider
 			user = User.find_for_authentication(email: external_email)
 			if user.present?
 				# if user exists by email, link the account
 				user.provider = auth_info.provider
 				user.password = Devise.friendly_token[0,20]
 				user.username = username
 				user.first_name = external_first_name
 				user.last_name = external_last_name
 				user.provider_metadata = external_metadata
 				user.skip_password_complexity_validation = true
 				user.save!
 			else
 				# if user entirely new, create the record
 				user = User.create!(provider: auth_info.provider,
 													 email: external_email,
 													 username: username,
 													 password: Devise.friendly_token[0,20],
 													 first_name: external_first_name,
 													 last_name: external_last_name,
 													 provider_metadata: external_metadata,
 													 skip_password_complexity_validation: true
 				)
 			end
 		end
   return user
 	end

end
