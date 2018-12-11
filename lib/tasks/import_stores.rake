namespace :import_stores do
  desc 'Reads store CSV and imports store users into UMS'

  task import_from_file: :environment do
    puts 'Importing Lowe\'s User List for Lowe\'s Installed Services!'
    puts '-------------'

    # Set type
    puts 'Setting Permission Type to LOWES'
    type = PermissionType.find_or_create_by(code:'LOWES', oauth_application: OauthApplication.find_by_name('INSTALLED-SERVICES'))

    # Import Lowe's users - Loop read the CSV file

    # Set Admin Users
    puts 'Setting Admin and CPO Lowe\'s users'

    lowes_admin = User.where(email: 'lowes_admin@owenscorning.com').first_or_create! do |u|
      u.username = 'lowesadmin'
      u.first_name = 'Lowe\'s'
      u.last_name = 'Admin'
      u.password = 'lowesadmin'
      u.skip_password_complexity_validation = true
      #u.skip_confirmation!
    end

    lowes_cpo = User.where(email: 'lowes_cpo@owenscorning.com').first_or_create! do |u|
      u.username = 'lowescpo'
      u.first_name = 'Lowe\'s'
      u.last_name = 'CPO'
      u.password = 'lowescpo'
      u.skip_password_complexity_validation = true
      #u.skip_confirmation!
    end

    puts 'Setting Admin and CPO Lowe\'s permissions'
    UserPermission.find_or_create_by(user: lowes_admin, permission_type: type, value: 0) # 0 for 'all'
    cpo_permissions = UserPermission.find_or_create_by(user: lowes_cpo, permission_type: type)

    puts 'Loading Lowe\'s CSV.'
    csv_text = File.read("#{Rails.root}/db/dataload/lowes-import.csv")

    puts 'Inserting Lowe\'s data, this may take a while.'

    # Insert store data for each row in the CSV
    ActiveRecord::Base.transaction do
      CSV.parse(csv_text, :headers => true) do |row|

        # Create the Lowe's Store User
        store_number = row['Store Number'].strip

        user = User.where(email: "lowes_store_#{store_number}@owenscorning.com").first_or_create! do |u|
          puts "Creating Store # #{store_number}"
          u.username = "lowes#{store_number}"
          u.first_name = 'Store'
          u.last_name = store_number.to_s
          u.password = "lowes#{store_number}#12"
          u.skip_password_complexity_validation = true
          #u.skip_confirmation!
        end

        # Create the Lowe's Store User Permission
        UserPermission.find_or_create_by(user: user, permission_type: type, value: store_number)

        # If this is marked as 'CPO', update the lowes_cpo user to have access to this store if not already included
        if row['CPO?'].strip == 'CPO' && (cpo_permissions.value.nil? || !cpo_permissions.value.include?(store_number))
          puts "Updating CPO to include #{store_number}"

          if cpo_permissions.value.nil?
            cpo_permissions.update(value: "#{store_number}")
          else
            cpo_permissions.update(value: "#{cpo_permissions.value},#{store_number}")
          end

        end

      end

      puts '##################'
      puts 'Import Stores Complete!'
    end

  end

end
