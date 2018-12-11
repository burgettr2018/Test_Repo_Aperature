module RailsAdmin
	module Config
		module Actions
			class RevokeAccessToken < RailsAdmin::Config::Actions::Base
				# This ensures the action only shows up for API tokens
				register_instance_option :visible? do
					authorized? && bindings[:object].class == ApiToken
				end
				register_instance_option :route_fragment do
					'revoke'
				end
				register_instance_option :template_name do
					'revoke_access_token'
				end
				# We want the action on members, not the collection
				register_instance_option :member do
					true
				end
				register_instance_option :link_icon do
					'icon-ban-circle'
				end
				# You may or may not want pjax for your action
				register_instance_option :pjax? do
					false
				end
				register_instance_option :action_name do
					:revoke_access_token
				end
				# copied from RailsAdmin::Config::Actions::Delete
				register_instance_option :http_methods do
					[:get, :delete]
				end
				register_instance_option :authorization_key do
					:destroy
				end
				register_instance_option :controller do
					proc do
						if request.get? # DELETE

							respond_to do |format|
								format.html { render @action.template_name }
								format.js   { render @action.template_name, layout: false }
							end

						elsif request.delete? # DESTROY

							redirect_path = nil
							@auditing_adapter && @auditing_adapter.delete_object(@object, @abstract_model, _current_user)
							if @object.destroy
								flash[:success] = t('admin.flash.successful', name: @model_config.label, action: t('admin.actions.delete.done'))
								redirect_path = index_path
							else
								flash[:error] = t('admin.flash.error', name: @model_config.label, action: t('admin.actions.delete.done'))
								redirect_path = back_or_index
							end

							redirect_to redirect_path

						end
					end
				end
			end
		end
	end
end