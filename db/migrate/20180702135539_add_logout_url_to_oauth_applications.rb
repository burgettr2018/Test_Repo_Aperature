class AddLogoutUrlToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :logout_url, :string
  end
end
