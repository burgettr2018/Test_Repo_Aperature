class AddApplicationUriToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :application_uri, :string
  end
end
