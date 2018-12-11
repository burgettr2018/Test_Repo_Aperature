module TrackingSavon
	class Client < Savon::Client
		def call(operation_name, locals = {}, &block)
			op = operation(operation_name)

			r = op.send(:build_request, op.build(locals, &block))

			if Rails.env.test?
				response = op.call(locals, &block)
			else
				t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
				req = ExternalApiRequestLog.create(
						time: Time.now.utc,
						method: 'POST',
						format: r.headers.try(:fetch, 'Content-Type', '(unknown)'),
						url: r.url.to_s,
						request_headers: r.headers,
						query_params: nil,
						request_body: r.body,
						trace_id: nil, #TODO trace_id
						access_token: nil #TODO access_token
				)
				begin
					response = op.call(locals, &block)
					t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					req.update_columns(status: response.http.code, response: response.http.body, response_headers: response.http.try(:headers).try(:to_hash), duration_ms: ((t2 - t1) * 1000).to_i)
				rescue Net::HTTPError => e
					t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					req.update_columns(status: e.http.try(:code), response: e.to_s, response_headers: e.http.try(:headers).try(:to_hash), duration_ms: ((t2 - t1) * 1000).to_i)
					raise
				rescue => e
					t2 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
					req.update_columns(status: "-1", response: e.message, duration_ms: ((t2 - t1) * 1000).to_i)
					raise
				end
			end

			response
		end
	end
	def self.client(globals = {}, &block)
		Client.new(globals, &block)
	end

	def self.observers
		Savon.observers
	end

	def self.notify_observers(operation_name, builder, globals, locals)
		Savon.notify_observers(operation_name, builder, globals, locals)
	end
end