module RailsAdmin
	module Config
		module Actions
			class RequeuePiFile < RailsAdmin::Config::Actions::Base
				# This ensures the action only shows up for Users
				register_instance_option :visible? do
					authorized? #&& (bindings[:object].class == MdmsJob || bindings[:object].class == UmsJob) && bindings[:object].try(:failed_at).present?
				end
				register_instance_option :route_fragment do
					'requeue_pi_file'
				end
				register_instance_option :template_name do
					'requeue_pi_file'
				end
				# We want the action on collection
				register_instance_option :collection do
					true
				end
				register_instance_option :link_icon do
					'fa fa-repeat'
				end
				# You may or may not want pjax for your action
				register_instance_option :pjax? do
					false
				end
				register_instance_option :action_name do
					:requeue_pi_file
				end
				# copied from RailsAdmin::Config::Actions::Delete
				register_instance_option :http_methods do
					[:get]
				end
				register_instance_option :authorization_key do
					:show
				end
				register_instance_option :controller do
					proc do
						if request.get?

							begin
								RceHelper.requeue_pi_file
								flash[:success] = 'Request to generate PI file has been queued'
							rescue => e
								flash[:alert] = 'Request to generate PI file failed!'
							end

							redirect_to request.referer
						end
					end
				end
			end
		end
	end
end