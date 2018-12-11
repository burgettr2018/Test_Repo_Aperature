module RailsAdmin
	module Config
		module Actions
			class RequeueDj < RailsAdmin::Config::Actions::Base
				# This ensures the action only shows up for Users
				register_instance_option :visible? do
					authorized? &&
						%w(MdmsJob UmsJob).include?(bindings[:abstract_model].model_name) &&
						(bindings[:object].nil? || bindings[:object].try(:failed_at).present?)
				end
				register_instance_option :bulkable? do
					true
				end
				register_instance_option :route_fragment do
					'requeue_dj'
				end
				register_instance_option :template_name do
					'requeue_dj'
				end
				# We want the action on members, not the collection
				register_instance_option :member do
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
					:requeue_dj
				end
				# copied from RailsAdmin::Config::Actions::Delete
				register_instance_option :http_methods do
					[:get, :post]
				end
				register_instance_option :authorization_key do
					:show
				end
				register_instance_option :controller do
					proc do
						if request.get?
							success = @object.retry!
							flash[:success] = 'Job has been re-queued' if success
							flash[:alert] = 'Job has failed to be re-queued!' unless success
							redirect_to request.referer
						else
							@objects = list_entries(@model_config, :destroy)
							results = []
							@objects.each do |object|
								begin
									results << object.retry!
								rescue => e
									results << false
								end
							end
							success_count = results.select{|r| r}.count
							failure_count = results.select{|r| !r}.count
							success_message = "#{success_count} #{success_count > 1 ? 'jobs have' : 'job has'} been re-queued"
							flash[:success] = "#{success_message}!" if failure_count == 0
							flash[:alert] = "#{failure_count} #{failure_count > 1 ? 'jobs have' : 'job has'} failed to be re-queued! #{success_message}." if failure_count > 0
							redirect_to request.referer
						end
					end
				end
			end
		end
	end
end