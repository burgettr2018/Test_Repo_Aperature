class ApiRequestMalformedInput
	def initialize(app, options = {})
		@app = app
	end

	def call(env)
		if malformed_response = respond_to_malformed_parameters(env)
			status, headers, response = malformed_response
			# log the malformed request to mongo
			if env['PATH_INFO'] =~ /\/api\/v1\/(?!me$)/
				log_request_mongo status, response, env
			end
			# return a clean error response, the app execution stops here
			[status, headers, response]
		else
			# continue normal execution of the middleware stack and app
			@app.call(env)
		end
	end

	private

	# inspiration
	# https://github.com/Casecommons/rack_respond_to_malformed_formats

	def respond_to_malformed_parameters(env)
		request = Rack::Request.new(env)

		case (env["HTTP_X_POST_DATA_FORMAT"] || request.content_type).to_s.downcase
			when /xml/
				parse_xml(request.body.read).tap { request.body.rewind }
			when /json/

				parse_json(request.body.read).tap { request.body.rewind }
			else
				false
		end
	end

	def parse_json(body)
		return false if body.nil? || body.to_s.empty?
		JSON.parse(body)
		false
	rescue JSON::ParserError
		[400, {"Content-Type" => "application/json"}, [{:error => "malformed json"}.to_json]]
	end

	def parse_xml(body)
		Nokogiri::XML(body) { |config| config.strict }
		false
	rescue Nokogiri::XML::SyntaxError
		response = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do
			error { message "malformed xml" }
		end

		[400, {"Content-Type" => "application/xml"}, [response.to_xml]]
	end

	def log_request_mongo status, response, env
		req = ActionDispatch::Request.new env
		access_token = decipher_auth_header(req.headers['Authorization'])

		incoming_content_type = env['CONTENT_TYPE']
		input = env["rack.input"]
		input.rewind
		raw_body = input.read

		mime_type = incoming_content_type.try(:split,';').try(:first)
		unless is_loggable_mime?(mime_type)
			raw_body = '(not captured due to content type)'
		end

		content_type = incoming_content_type #headers['Content-Type']
		response_body = ""
		response.each { |part| response_body += part }

		mime_type = content_type.try(:split,';').try(:first)
		unless is_loggable_mime?(mime_type)
			response_body = '(not captured due to content type)'
		end

		ApiRequestLog.create!(
				time: Time.now.utc,
				method: env['REQUEST_METHOD'],
				format: content_type,
				request_format: incoming_content_type,
				url: env['PATH_INFO'],
				status: status,
				ip: req.remote_ip,
				access_token: access_token,
				trace_id: env['HTTP_X_AMZN_TRACE_ID'],
				query_params: env['rack.request.query_hash'],
				raw_request_body: raw_body,
				parsed_request_body: "malformed format: request body cannot be parsed",
				response: response_body,
				oauth_application_id: OauthApplication.find_by_name('UMS').id,
				duration_ms: 0
		)
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
