class ActionMailer::Preview
	class << self
		def call(email, params = {})
			preview = new
			preview.params = params if preview.respond_to?(:params=)
			message = preview.public_send(email)
			inform_preview_interceptors(message)
			message
		end
	end
end

class Rails::MailersController
	prepend_view_path 'app/views'
	def preview
		if params[:path] == @preview.preview_name
			@page_title = "Mailer Previews for #{@preview.preview_name}"
			render action: "mailer"
		else
			@email_action = File.basename(params[:path])

			if @preview.email_exists?(@email_action)
				@email = @preview.call(@email_action, params)

				if params[:part]
					part_type = Mime::Type.lookup(params[:part])

					if part = find_part(part_type)
						response.content_type = part_type
						render text: part.respond_to?(:decoded) ? part.decoded : part
					else
						raise AbstractController::ActionNotFound, "Email part '#{part_type}' not found in #{@preview.name}##{@email_action}"
					end
				else
					@part = find_preferred_part(request.format, Mime[:html], Mime[:text])
					render action: "email", layout: false, formats: %w[html]
				end
			else
				raise AbstractController::ActionNotFound, "Email '#{@email_action}' not found in #{@preview.name}"
			end
		end
	end
	class << self
		def part_query(mime_type)
			request.query_parameters.merge(part: mime_type).to_query
		end
	end
end