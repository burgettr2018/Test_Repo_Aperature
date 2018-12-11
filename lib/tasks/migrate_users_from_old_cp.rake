def create_payer(email,payer_number)
  gateway_id = 2 #NA # RefreshPayer.where(payer_id:payer_number).first.try(:gateway_id)
  user = User.find_by_email(email)

  rp = RefreshPayer.find_or_create_by!(
      user_id:user .id,
      payer_id: payer_number,
      gateway_service_id:gateway_id) do
        puts "Create new RefreshPayer record: #{email} #{payer_number}"
      end if !user.blank?


  puts "NO GATEWAYID #{rp.id}" if gateway_id.blank?
end

def create_payers(email,payers)
  payers.each do |p|
    create_payer(email,p["AccountNumber"])
  end
end


def   create_refreshpayers(users)
  users.each do |u|
    puts "Processing #{u[0]}\n"
    u[1].each do |p|
      a = p["permission"]
      if a.include?('_SOLDTO')
        p['value'].split(",").each do |per|
          #puts "found soldto #{per.split("_")[0]}\n"
          soldto_number = per.split("_")[0]
          payers = MDMSPROD.payers_for_soldto(soldto_number)

          if payers.blank?
            puts "No payers for soldto #{soldto_number}"
          else
            create_payers(u[0], payers)
          end
        end
      elsif a.include?('_SHIPTO')
        p['value'].split(",").each do |per|
          #puts "found shipto #{per.split("_")[0]}\n"
          shipto_number = per.split("_")[0]
          payers = MDMSPROD.payers_for_shipto(shipto_number)

          if payers.blank?
            puts "No payers for shipto #{soldto_number}"
          else
            create_payers(u[0], payers)
          end
        end

      elsif a.include?('_PAYER')
        p['value'].split(",").each do |per|
          #puts "found payer #{per.split("_")[0]}\n"
          payer_number = per.split("_")[0]
          create_payer(u[0], payer_number)
        end
      end
    end
  end
end

namespace :migrate_user_from_old_cp do
  desc 'Reads legacy_cp_portal_users.csv and stores data into update_permissions (UMS)'

  task import_from_file: :environment do
    puts 'Importing users from old_users.csv: !'
    puts '-------------------------------------------------'
    # Import Users - Loop read the CSV file
    csv_text = File.read("#{Rails.root}/db/dataload/legacy_cp_portal_users.csv")

    #Create output file for storing new user link and info
    puts "Creating Output file for updated records"

    user_file = './db/dataload/new_users_invites.csv'
    #Clean out old file if exists
    if File.exist?(user_file)
      File.delete(user_file)
    end
    output_file = File.open(user_file, 'w')

    puts 'Inserting New Users from file'

    #Setup our Hash
    users = {}
    current_application = OauthApplication.find_by_name('CUSTOMER_PORTAL')
    # Insert store data for each row in the CSV
    # IMPORTANT - This has not been checked for NON-CONTIGUOUS values in the CSV. It *should* work based on line 32
    ActiveRecord::Base.transaction do
      CSV.parse(csv_text, :headers => true) do |row|
        # Create the user hash from table values
        if users.keys.last != row[0]
          users[row[0]] = []
        end

        if !users[row[0]].find{|p| p['permission'] == row[1]}
          users[row[0]] << {'permission'=>row[1], 'value'=>"", 'application'=>'MDMS'}
        else
          users[row[0]].find{|p| p['permission'] == row[1]}['value'] << ","
        end

        users[row[0]].find{|p| p['permission'] == row[1]}['value'] << "#{row[2]}"

      end



        #Migrate user and permissions
        users.each do |email|
          user = User.where(email: "#{email[0].downcase}").first_or_create! do |u|
            u.email = email[0]
            u.username = email[0]
            u.password = "Migrated1234!"
            puts "New User #{u.username}"
          end

          #Cycle through permissions
          email[1] <<  {'permission'=>'OA_BMG', 'application'=>'MDMS', 'value'=>''}
          user.update_permissions_from_hash(email[1], user, current_application)


          ua = UserApplication.where(oauth_application: current_application,user_id:  user.id).first_or_create do |ua|
              ua.invitation_status = 'invited'
              ua.postpone_invite = true
              puts "New User Application for user: #{user.id}"
          end

            #user.user_applications << ua
            ua.invite(invited_by_id = nil, 120.days, false)
            if  ua.invitation_token_raw.blank?
              puts "#{user.email} missing invitation link?"
            else
              invite_url = "http://login.owenscorning.com/users/invitations/accept/" + ua.invitation_token_raw
              #Write values of interest to file:
              output_file.write(user.email + ',' + invite_url + "\n")
            end

        end



      create_refreshpayers(users)



      puts '########################'
      puts 'User Migration Complete!'
    end

  end

  task invite_from_file: :environment do
    csv_text = File.read("./db/dataload/new_users_invites.csv")
    ActiveRecord::Base.transaction do
      CSV.parse(csv_text, :headers => true) do |row|
        #Grab all the new users, lookup application and Queue Invite.
        ua = User.find_by(email: row[0]).user_applications.last
        UserMailer.delay(run_at: 0).invitation(ua.id, ua.invitation_token_raw, ua.invitation_expires_in)
        puts "#{row[0]} has been queued for invite"
      end
    end
  end

end
