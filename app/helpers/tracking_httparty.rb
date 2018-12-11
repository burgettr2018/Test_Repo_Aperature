require Rails.root.join("lib/smart_uri")
module TrackingHttparty
	include HTTParty
	logger Rails.logger, :info
	debug_output $stdout

	module ClassMethods
		def perform_request(http_method, path, options, &block)
			final_options = HTTParty::ModuleInheritableAttributes.hash_deep_dup(default_options).merge(options)
			if final_options[:headers] && headers.any?
				final_options[:headers] = headers.merge(final_options[:headers])
			end
			if final_options[:cookies] || default_cookies.any?
				final_options[:headers] ||= headers.dup
				final_options[:headers]["cookie"] = cookies.merge(final_options.delete(:cookies) || {}).to_cookie_string
			end

			r = HTTParty::Request.new(http_method, path, final_options)

			if Rails.env.test?
				response = super(http_method, path, options, &block)
			else
				t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
				req = ExternalApiRequestLog.create(
						time: Time.now.utc,
						method: http_method::METHOD,
						format: final_options[:headers].try(:fetch, 'Content-Type', 'application/x-www-form-urlencoded'),
						url: SmartURI.join(self.base_uri, path),
						request_headers: final_options[:headers],
						query_params: Rack::Utils.parse_nested_query(r.uri.query).presence,
						request_body: final_options[:body],
						trace_id: nil, #TODO trace_id
						access_token: nil #TODO access_token
				)
				begin
					response = super(http_method, path, options, &block)
					t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					req.update_columns(status: response.code, response: response.body, response_headers: response.headers.try(:to_hash), duration_ms: ((t2 - t1) * 1000).to_i)
				rescue => e
					t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					req.update_columns(status: "-1", response: e.message, duration_ms: ((t2 - t1) * 1000).to_i)
					raise
				end
			end

			response
		end
	end
	extend ClassMethods

	def self.included( other )
		HTTParty.included(other)
		other.extend( ClassMethods )
	end
end