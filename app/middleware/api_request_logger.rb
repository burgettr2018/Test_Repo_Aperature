class ApiRequestLogger
	def initialize(app, options = {})
		@app = app
	end

	def call(env)
		t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
		# log only requests to api endpoints
		if env['PATH_INFO'] =~ /\/api\/v1\/(?!me$)/
			request = Rack::Request.new(env)
			access_token = decipher_auth_header(ActionDispatch::Http::Headers.new(env)['Authorization'])

			incoming_content_type = (env["HTTP_X_POST_DATA_FORMAT"] || request.content_type).to_s
			raw_body = request.body.read
			request.body.rewind

			mime_type = incoming_content_type.try(:split,';').try(:first)
			unless is_loggable_mime?(mime_type)
				raw_body = '(not captured due to content type)'
			else
				begin
					parsed_body = JSON.parse(raw_body) if raw_body
				rescue => e
					parsed_body = "Cannot parse body: #{e.message}"
				end
			end

			env['api_log'] ||= ApiRequestLog.create!(
					time: Time.now.utc,
					method: env['REQUEST_METHOD'],
					request_format: incoming_content_type,
					url: env['PATH_INFO'],
					status: -1,
					ip: request.ip,
					access_token: access_token,
					trace_id: env['HTTP_X_AMZN_TRACE_ID'],
					query_params: env['rack.request.query_hash'],
					raw_request_body: raw_body,
					parsed_request_body: parsed_body,
					oauth_application_id: OauthApplication.find_by_name('UMS').id
			)
		end

		status, headers, response = @app.call(env)

		api_log = env['api_log']
		if api_log.present?
			content_type = headers['Content-Type']
			response_body = ""
			# read the JSON string line by line
			response.each { |part| response_body += part }

			mime_type = content_type.try(:split,';').try(:first)
			unless is_loggable_mime?(mime_type)
				response_body = '(not captured due to content type)'
			end

			t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
			api_log.update(
				status: status,
				response: response_body,
				duration_ms: ((t2 - t1) * 1000).to_i
			)
		end

		[status, headers, response]
	end

	def is_loggable_mime?(mime_type)
		mime_type =~ /^text\// || mime_type == 'application/json' || mime_type == 'application/xml' || mime_type == 'application/x-www-form-urlencoded'
	end

	def decipher_auth_header(authorization)
		if authorization =~ /^Bearer\s/
			authorization.gsub(/^Bearer\s/, '')
		elsif authorization =~ /^Basic\s/
			token, _ = Base64.decode64(authorization.gsub(/^Basic\s/, '')).split(/:/, 2)
			token
		else
			nil
		end
	end
end