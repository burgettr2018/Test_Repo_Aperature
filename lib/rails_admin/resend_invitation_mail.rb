module RailsAdmin
	module Config
		module Actions
			class ResendInvitationMail < RailsAdmin::Config::Actions::Base
				# This ensures the action only shows up for Users
				register_instance_option :visible? do
					authorized? &&
					(		(bindings[:object].class == UserApplication && RceHelper.is?(bindings[:object].try(:oauth_application)) && %w(invited re-invited).include?(bindings[:object].try(:invitation_status))) ||
							(bindings[:object].class == User && bindings[:object].try(:application, 'CONTRACTOR_PORTAL').present? && %w(invited re-invited).include?(bindings[:object].try(:application, 'CONTRACTOR_PORTAL').try(:invitation_status)))
					)
				end
				register_instance_option :route_fragment do
					'resend_invitation_mail'
				end
				register_instance_option :template_name do
					'resend_invitation_mail'
				end
				# We want the action on members, not the collection
				register_instance_option :member do
					true
				end
				register_instance_option :link_icon do
					'fa fa-envelope-o'
				end
				# You may or may not want pjax for your action
				register_instance_option :pjax? do
					false
				end
				register_instance_option :action_name do
					:resend_invitation_mail
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

							@object.invite if @object.class == UserApplication
							@object.application('CONTRACTOR_PORTAL').try(:invite) if @object.class == User
							flash[:success] = 'Re-queued invitation email'

							redirect_to request.referer
						end
					end
				end
			end
		end
	end
end