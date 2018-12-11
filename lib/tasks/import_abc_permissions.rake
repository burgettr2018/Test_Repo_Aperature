namespace :import_abc_permissions do
  desc 'Reads abc_permissions.csv and stores data into ABCLocationPermissions (UMS)'

  task import_from_file: :environment do
    puts 'Importing ABC Permissions from abc_permissions.csv!'
    puts '-------------'

    # Set ABC Permission Type
    # puts 'Setting Permission Type to ABC_OVERRIDE'
    # PermissionType.find_or_create_by(code:'ABC_OVERRIDE', oauth_application: OauthApplication.find_by_name('???'))

    # Import ABC Permissions - Loop read the CSV file

    puts 'Loading abc_permissions CSV.'
    csv_text = File.read("#{Rails.root}/db/dataload/abc_permissions.csv")

    puts 'Inserting ABC data, please stand by.'

    # Insert store data for each row in the CSV
    ActiveRecord::Base.transaction do
      CSV.parse(csv_text, :headers => true) do |row|
        # Create the ABC Permission from a row
        email = row['emailAddress']
        permission = row['permission_type']
        value = row['permission_value']

        #Since these are non-unique by multiple columns we must check several attributes
        AbcLocationPermission.where(email: "#{email}", permission: "#{permission}", value: "#{value}").first_or_create! do |p|
          p.location_type = row[0] #TODO find out why 'location_type' doesn't work???
          p.location_number = row['location_number']
          p.location = row['location']
          p.email = email
          p.permission = permission
          p.value = value
          puts "Inserted New Record for value #{p.value}"
        end

      end

      puts '##################'
      puts 'Import ABC Permissions Complete!'
    end

  end

end
