namespace :import_abc_permissions_update do
  desc 'Reads abc_permissions.csv and stores data into ABCLocationPermissions (UMS)'

  task import_from_file: :environment do
    puts 'Importing ABC Permissions from' + "#{ARGV}"
    puts '-------------'

    # Set ABC Permission Type
    # puts 'Setting Permission Type to ABC_OVERRIDE'
    # PermissionType.find_or_create_by(code:'ABC_OVERRIDE', oauth_application: OauthApplication.find_by_name('???'))

    # Import ABC Permissions - Loop read the CSV file

    puts 'Loading abc_permissions CSV.'
    # csv_text = File.read("#{Rails.root}/db/dataload/abc_permissions.csv")
    puts "#{ARGV[1]} is the file and path"
    csv_text = File.read("#{Rails.root}/db/dataload/abc_as_of_11042018.csv")

    puts "Creating Output file for updated records"
    output_file = File.open("#{Rails.root}/db/dataload/abc_permissions_updated_records.csv", 'w')

    puts 'Inserting ABC data, please stand by.'

    # Insert store data for each row in the CSV
    ActiveRecord::Base.transaction do
      CSV.parse(csv_text, :headers => true) do |row|
        # Create the ABC Permission from a row
        # email = row['emailAddress'] TODO - this should come back into play for non-branch permisson
        permission = "OA_SOLDTO"
        #Original dataset is prefaced with "000" and contains "_" between fields. TODO - check this.
        puts "#{ row[0]}"
        value = row[0] + "_" + row['Division'] + "_" + row['Sales Organization']

        #Since these are non-unique by multiple columns we must check several attributes -TODO does this still hold true?
        #Skip any 'Name' field which begins with "ZZ", ABC's delete record identifier
        if row[1][0..1]!= "ZZ" && row[10][0..1] != "ZZ"
          p = AbcLocationPermission.where(permission: "#{permission}", value: "#{value}",location_number:row['ST2']).first_or_create!
          output_file.write(p.location_number + ',' + p.permission + ',' + p.value + ',' + "\n")
          puts "Inserted New Record for value #{p.value}"
        else
          #One or many Name fields have been marked with "ZZ". TODO - Sometimes only ONE partner
          #has been flagged for removal, best guess is permission should persist.
          abc_record = AbcLocationPermission.where(permission: "#{permission}", value: "#{value}",location_number:row['ST2']).first
          if abc_record != nil
            puts "destroying #{abc_record.value}, Partner #{row['Partner']} flagged with ZZ"
            abc_record.destroy
          else
            puts "No Record Found for #{value}, Removal Unnecessary"
          end
        end
      end
      output_file.close
      puts '##################'
      puts 'Import ABC Permissions Complete!'
    end

  end

end
