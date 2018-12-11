class InternalController < ApplicationController
	before_action :check_users_manage_permission
	before_action :get_permissions
	skip_after_action :verify_authorized, :verify_policy_scoped

	def index
	end

	def create
		id = create_params[:employee_id]
		emp = MdmsEmployee.where(employee_id: id).first
		head :bad_request and return if emp.nil?

		user = User.where('lower(email) = ?', emp.email_address.downcase).first
		user = User.create!(provider: 'okta',
											 email: emp.email_address.downcase,
											 username: "#{emp.network_id}@corp.owenscorning.com",
											 password: Devise.friendly_token[0,20],
											 first_name: emp.first_name,
											 last_name: emp.last_name,
											 skip_password_complexity_validation: true
		) if user.nil?

		existing_permission_ids = user.user_permissions.joins(:permission_type).where(permission_types: {is_for_employees: true}).pluck('permission_types.id')
		incoming_permission_ids = create_params.keys
															 .select{|k| /^pt_/ =~ k}
															 .select{|k| params[:"pt_#{k}"] != '0'}
															 .map{|k| k.sub(/^pt_/, '').to_i}
		incoming_permission_values = Hash[create_params.keys
																	.select{|k| /^value_/ =~ k}
																	.map{|k| k.sub(/^value_/, '').to_i}
																	.map{|k|
																		[k, create_params[:"value_#{k}"]]
																	}]

		permissions_to_drop = existing_permission_ids-incoming_permission_ids
		permissions_to_add = incoming_permission_ids-existing_permission_ids
		permissions_to_edit = incoming_permission_values.keys - permissions_to_add

		user.user_permissions.joins(:permission_type).where(permission_types: {id: permissions_to_drop}).destroy_all
		permissions_to_add.each do |p|
			UserPermission.create!(user_id: user.id, permission_type_id: p, value: (incoming_permission_values[p]||'*'))
		end
		permissions_to_edit.each do |p|
			user.user_permissions.where(permission_type_id: p).first.update_attributes(value: incoming_permission_values[p]||'*')
		end

		head :ok
	end

	def ajax_value_search
		q = ajax_value_search_params[:q]
		values = UserPermission.where(permission_type_id: ajax_value_search_params[:permission_type_id]).where("','||coalesce(value,'')||',' ilike ?", ",%#{q}%,")
								 .pluck(:value)
								 .map{|v| v.try(:split, ',')}
								 .flatten.uniq
								 .select{|v|
									 /#{q}/i =~ v
								 }
		render json: {
				results: values
		}
	end

	def ajax_employee_search
		q = ajax_employee_search_params[:q]
		employees = MdmsEmployee.where('first_name ilike ? OR last_name ilike ? OR employee_id::text like ? OR email_address ilike ?', *((1..4).map{|_|"%#{q}%"}))
		render json: {
				results: employees.pluck(:employee_id, :first_name, :last_name, :location_name, :email_address).map{|row|
					{
							employee_id: row[0],
							first_name: row[1],
							last_name: row[2],
							location_name: row[3],
							email_address: row[4]
					}
				}
		}
	end

	def ajax_employee
		employee = MdmsEmployee.where(employee_id: ajax_employee_params[:id]).first
		user = User.where('lower(email) = ?', employee.email_address.downcase).first
		render json: {
				data: {
						email: employee.email_address,
						first_name: employee.first_name,
						last_name: employee.last_name,
						location_name: employee.location_name,
						user_id: user.try(:id),
						permissions: (user.try(:user_permissions).try(:to_a)||[]).map{|p|
							{
									application: p.permission_type.oauth_application.name,
									code: p.permission_type.code,
									value: p.value
							}
						}
				}
		}
	end

	private
	def get_permissions
		@permissions = PermissionType.joins(:oauth_application).where(is_for_employees: true)
	end

	def check_users_manage_permission
		if user_signed_in?
			user_not_authorized unless current_user.admin || current_user.has_permission?('UMS', 'USERS_MANAGE')
		else
			redirect_to new_user_session_path
		end
	end

	def create_params
		params.require(:internal_user).permit!
	end

	def ajax_value_search_params
		params.permit(:q, :permission_type_id)
	end

	def ajax_employee_search_params
		params.permit(:q)
	end

	def ajax_employee_params
		params.permit(:id)
	end
end
