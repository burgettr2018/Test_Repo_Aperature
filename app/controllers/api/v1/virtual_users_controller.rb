class Api::V1::VirtualUsersController < Api::V1::ApiController

	before_action :check_application_permission

	def enable
		user = User.find_by_guid(able_params[:guid])
		head 400 and return if user.nil?
		account = user.get_permission_value('CONTRACTOR_PORTAL', 'ACCOUNT').try(:downcase)
		given_account = able_params[:account].try(:downcase)
		head 400 and return if account != given_account
		level = user.get_permission_value('CONTRACTOR_PORTAL', 'LEVEL').try(:downcase)
		locations = (user.get_permission_value('CONTRACTOR_PORTAL', 'LOCATION').try(:downcase)||'').split(',').map(&:strip)
		given_location = able_params[:location].try(:downcase)
		head 400 and return if level == 'location' && !locations.include?(given_location)

		Contractor::RceVirtualAdfsUser.find_or_create_by!(user_id: user.id, location_guid: given_location)
		head 200
	end
	def disable
		user = User.find_by_guid(able_params[:guid])
		head 404 and return if user.nil?
		vuser = Contractor::RceVirtualAdfsUser.find_by(user_id: user.id, location_guid: able_params[:location])
		head 404 and return if vuser.nil?
		vuser.destroy
		head 200
	end

	private
	def able_params
		params.require(:user).permit(:guid, :account, :location)
	end

	def check_application_permission
		forbidden unless @current_user.has_permission?('UMS', 'VIRTUAL_USERS_MANAGE')
	end
end
