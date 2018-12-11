class Api::V1::PortalssoController  < Api::V1::ApiController
	ALLOWED_SITES = %w(https://portalsso.owenscorning.com https://grvv8560)
	protect_from_forgery only: :check_post, with: :exception

	skip_before_action :load_user
	skip_before_action :check_application_permission

	def check
		@check_path = api_v1_portalsso_check_post_url
		set_access_control_headers
		render 'check.js'
	end
	def check_options
		if access_allowed?
			set_access_control_headers
			head :ok
		else
			head :forbidden
		end
	end
	def check_post
		verify_authenticity_token
		if access_allowed?
			data = JSON.parse(request.body.read, {symbolize_names: true})
			set_access_control_headers

			# there may be other ways, lookup "legacy username" on UMS in case of owner account, lookup legacy username in AD and get member id, then lookup owner account?
			# to call this done until we figure out cutover plan, look by username only
			# ideally, we will create the new owner with the proper username = AD username, so ideally, this won't need to change
			user = User.find_by_username(data[:username])
			redirect = user.present? && user.application('CONTRACTOR_PORTAL').present? ? true : false

			# is this ok?
			flash[:notice] = 'Your invitation has not yet been accepted, please check your email for account activation link' if user.present? && user.application('CONTRACTOR_PORTAL').invitation_status =~ /invited/
			session[:attempted_username] = data[:username]

			render json: { username: data[:username], redirect: redirect, url: new_user_session_url }
		else
			head :forbidden
		end
	end

	private

	def set_access_control_headers
		headers['Access-Control-Allow-Credentials'] = 'true'
		headers['Access-Control-Allow-Origin'] = request.env['HTTP_ORIGIN']
		headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
		headers['Access-Control-Allow-Headers'] = '*,cookie,Content-Type,x-requested-with,x-csrf-token'
	end
	def access_allowed?
		return ALLOWED_SITES.include?(request.env['HTTP_ORIGIN'])
	end
end