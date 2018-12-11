class AddProperNameToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :proper_name, :string
    OauthApplication.all.each do |a|
      a.proper_name = a.name.titleize
      a.proper_name = 'Lowe\'s Installed Services' if a.name == 'INSTALLED-SERVICES'
      a.proper_name = 'OCConnect™ Resource Center' if a.name == 'CONTRACTOR_PORTAL'
      a.proper_name = 'owenscorning.com' if a.name == 'OC_COM'
      a.save!
    end
  end
end
