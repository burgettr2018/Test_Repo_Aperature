namespace :import_contractors do
  desc 'Reads contractor CSV and imports contractors into UMS'

  # Run this command: rake import_contractors:import_from_file
  task import_from_file: :environment do

    puts 'Importing Contractors for Lowe\'s Installed Services!'
    puts '-------------'


    # Set type
    puts 'Setting Permission Type to CONTRACTOR'
    type = PermissionType.find_or_create_by(code:'CONTRACTOR', oauth_application: OauthApplication.find_by_name('INSTALLED-SERVICES'))

    # Import contractors - Loop read the CSV file

    puts 'Loading Contractor CSV.'
    csv_text = File.read("#{Rails.root}/db/dataload/contractor-import3.csv")
    #csv = CSV.parse(csv_text, :headers => true)
    puts 'Inserting Contractor data, this may take a while.'

    # Insert store data for each row in the CSV
    ActiveRecord::Base.transaction do
      CSV.parse(csv_text, :headers => true) do |row|
        new_email = row['Email'].downcase.strip
        puts "Loading Contractor #{new_email}"

        if new_email.present? && !new_email.nil?
          begin
            user = User.where(email: new_email).first_or_create! do |u|
                puts "Creating Contractor #{new_email}"
                u.first_name = row['FirstName']
                u.last_name = row['LastName']
                u.password = 'password'
                u.skip_password_complexity_validation = true
                #u.skip_confirmation!
            end
          rescue ActiveRecord::RecordInvalid
            sleep 5
            @save_retry_count =  (@save_retry_count || 5)
            retry if( (@save_retry_count -= 1) > 0 )
            raise $ERROR_INFO

            #puts 'Sleeping for 1 second, then find user..'
            #sleep 1

            #puts "Retrying find_or_create for #{new_email}"
            #retry
            #user = User.find_by_email(new_email)
            #puts "Found user #{new_email} ? #{user.present?}"
          end

          # Check if it exists in this table, if so, just update the 'value' column with the vendor numbers
          if !user.nil? && user.present? && user.email.present?
            user_permission = UserPermission.find_by_user_id(user.id)
            if user_permission.nil? && !user.nil?
              puts "Creating new permissions for #{user.email}"
              UserPermission.create(user: user, permission_type: type, value: row['VendorNumber'])
            elsif !(user_permission.value.include? row['VendorNumber']) # Update if this Vendor Number is missing from permissions.
              puts "Updating permissions for #{user.email}"
              user_permission.update(value: "#{user_permission.value},#{row['VendorNumber']}")
            else
              puts "Permission already set for #{user.email}"
            end
          else
            puts "Nil user?? #{new_email}"
          end

        end
      end
    end

    puts 'Contractor Table creation and data import complete!'

  end

end
