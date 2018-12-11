module Oauth
	class TokensController < Doorkeeper::TokensController
		def create
			response = super
			if @authorize_response &&  Doorkeeper::OAuth::TokenResponse === @authorize_response && @authorize_response.token
				if @authorize_response.token.resource_owner_id
					user = User.find(@authorize_response.token.resource_owner_id)
					application = OauthApplication.find(@authorize_response.token.application_id)
					SsoRequestLog.log(user, application, request, true, 'OK', access_token: @authorize_response.token.token)
				end
			end
			response
		end
		def revoke
			#TODO - SLO, alhough it may not be possible without backchannel calls
			#SsoRequestLog.find_by_access_token(request.POST['token'])
			super
		end
	end
end