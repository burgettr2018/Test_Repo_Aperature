class ImpersonationController < ApplicationController
	before_action :check_impersonate_permission, only: [:form, :start]
	before_action :check_impersonate_permission_ajax, only: [:ajax_member_profiles, :ajax_contractor_portal_location_users]
	skip_after_action :verify_authorized

	def form
	end

	def resource
		@user_to_impersonate
	end

	def start
		user_id = current_user.id
		@user_to_impersonate = User.find_by_email(params[:impersonation].try(:[], :user))

		redirect_to users_impersonate_path and return if @user_to_impersonate.nil?
		redirect_to users_impersonate_path and return if /@owenscorning\.com$/ =~ @user_to_impersonate.email && !current_user.admin

		if sign_in(:user, @user_to_impersonate)
			session.options[:id] = session.instance_variable_get(:@by).generate_sid
			session.options[:renew] = false

			Contractor::ImpersonationLog.create!(user_id: user_id, impersonated_user_id: @user_to_impersonate.id, session_id: session.id, started_at: DateTime.now)
		end
		redirect_to root_url
	end

	def ajax_member_profiles
		member_profiles = Contractor::MemberProfile.where('membership_number ILIKE ?', "#{params[:q]}%").where(loyalty_program_code: 'OCCN-US').order(membership_number: :asc)
		render json: member_profiles.to_a.map{
			|m|
			{
					membershipNumber: m.membership_number,
					companyName: m.company_name,
					companyStreet1: m.company_street1,
					companyCity: m.company_city,
					companyState: m.company_state,
					companyZip: m.company_zip,
					companyCountryCodeAlpha3: 'USA'
			}
		}
	end

	def ajax_contractor_portal_location_users
		member_profiles = Contractor::MemberProfile.for_status('active').where(membership_number: params[:member_id])
		user_ids = []
		member_profiles.each do |m|
			user_ids = user_ids + m.users.pluck(:id)
		end

		user_ids = user_ids.uniq

		active_users = User.for_invitation_status('CONTRACTOR_PORTAL', 'complete').where(id: user_ids)

		if member_profiles.any?
			user_emails = active_users.pluck(:email)
			user_emails = user_emails.reject{|email| /@owenscorning\.com$/ =~ email} unless current_user.admin
			render json: {company_name: member_profiles.first.company_name, user_emails: user_emails}
		else
			render json: {}
		end

	end

	private

	def check_impersonate_permission_ajax
		if user_signed_in?
			forbidden unless current_user.has_permission?('CONTRACTOR_PORTAL', 'IMPERSONATE')
		else
			no_access
		end
	end

	def no_access
		render json: {error:'You are not authorized to perform this action.'}, status: 401
	end
	def forbidden
		render json: {error:'You are not authorized to perform this action.'}, status: 403
	end

	def check_impersonate_permission
		if user_signed_in?
			user_not_authorized unless current_user.has_permission?('CONTRACTOR_PORTAL', 'IMPERSONATE')
		else
			redirect_to new_user_session_path
		end
	end

	def start_params
		params.require(:impersonate).permit(:member_id, :user)
	end

	def ajax_contractor_portal_location_users_params
		params.permit(:member_id)
	end
end
