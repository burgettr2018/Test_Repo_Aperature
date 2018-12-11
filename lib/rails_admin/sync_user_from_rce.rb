module RailsAdmin
	module Config
		module Actions
			class SyncUserFromRce < RailsAdmin::Config::Actions::Base
				# This ensures the action only shows up for Users
				register_instance_option :visible? do
					authorized? &&
					(		#(bindings[:object].class == UserApplication && RceHelper.is?(bindings[:object].try(:oauth_application))) ||
							(bindings[:object].class == User && bindings[:object].try(:application, 'CONTRACTOR_PORTAL').present?)
					)
				end
				register_instance_option :route_fragment do
					'sync_user_from_rce'
				end
				register_instance_option :template_name do
					'sync_user_from_rce'
				end
				# We want the action on members, not the collection
				register_instance_option :member do
					true
				end
				register_instance_option :link_icon do
					'fa fa-cloud-download'
				end
				# You may or may not want pjax for your action
				register_instance_option :pjax? do
					false
				end
				register_instance_option :action_name do
					:sync_user_from_rce
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

							@object.update_from_rce! if @object.class == User
							flash[:success] = 'Re-synced from RCE'

							redirect_to request.referer
						end
					end
				end
			end
		end
	end
end