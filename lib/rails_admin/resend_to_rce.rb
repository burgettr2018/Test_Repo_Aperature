module RailsAdmin
	module Config
		module Actions
			class ResendToRce < RailsAdmin::Config::Actions::Base
				# This ensures the action only shows up for Users
				register_instance_option :visible? do
					authorized? &&
					(		(bindings[:object].class == UserApplication && RceHelper.is?(bindings[:object].try(:oauth_application))) ||
							(bindings[:object].class == User && bindings[:object].try(:application, 'CONTRACTOR_PORTAL').present?)
					)
				end
				register_instance_option :route_fragment do
					'resend_to_rce'
				end
				register_instance_option :template_name do
					'resend_to_rce'
				end
				# We want the action on members, not the collection
				register_instance_option :member do
					true
				end
				register_instance_option :link_icon do
					'fa fa-share-square-o'
				end
				# You may or may not want pjax for your action
				register_instance_option :pjax? do
					false
				end
				register_instance_option :action_name do
					:resend_to_rce
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


							RceHelper.update_user_auth_status(@object.user) if @object.class == UserApplication
							RceHelper.update_user_auth_status(@object) if @object.class == User
							flash[:success] = 'Re-queued call to RCE'

							redirect_to request.referer
						end
					end
				end
			end
		end
	end
end