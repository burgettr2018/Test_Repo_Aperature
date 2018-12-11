namespace :ums do
	desc 'Create permissions for customer portal beta'
	task setup_beta_users: :environment do

		start_time = DateTime.now

		permission_type = PermissionType.joins(:oauth_application).where(oauth_applications: { name: 'MDMS' }, code: 'OA_PAYER').first
		target_permission_type = PermissionType.joins(:oauth_application).where(oauth_applications: { name: 'MDMS' }, code: 'OA_NEWSITE').first
		user_permissions = UserPermission.where(permission_type_id: permission_type.id).where('value like ?', '%1009898_%')

		users = User.where(id: user_permissions.select(:user_id))
		puts "Updating records:  #{users.count}"

		users.each do |row|
			begin
				if row.user_permissions.where(permission_type_id: target_permission_type.id).first.nil?
					puts "Adding #{row[:email]}"
					row.user_permissions << UserPermission.create!(permission_type_id: target_permission_type.id, value: '*')
				else
					puts "Skipping #{row[:email]}"
				end
			rescue => e
				puts e.message
				e.backtrace.each { |line| puts line }
			end
		end

		puts "Time to run rake task: #{(DateTime.now-start_time)*24*60*60.to_f} seconds"

	end

	desc 'remind users with pending invitations'
	task remind_invites: :environment do
		UserApplication.remind_invites
	end
	desc 'expire users with expired invitations'
	task expire_invites: :environment do
		UserApplication.expire_invites
	end
end
