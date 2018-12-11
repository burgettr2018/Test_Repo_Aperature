module RailsAdmin
	module Config
		module Actions
			class GetJwt < RailsAdmin::Config::Actions::Base
				# This ensures the action only shows up for Users
				register_instance_option :visible? do
					authorized? && bindings[:object].class == User
				end
				register_instance_option :route_fragment do
					'get_jwt'
				end
				register_instance_option :template_name do
					'get_jwt'
				end
				# We want the action on members, not the collection
				register_instance_option :member do
					true
				end
				register_instance_option :link_icon do
					'fa fa-key'
				end
				# You may or may not want pjax for your action
				register_instance_option :pjax? do
					false
				end
				register_instance_option :action_name do
					:get_jwt
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

							flash[:success] = @object.get_jwt

							redirect_to request.referer
						end
					end
				end
			end
		end
	end
end