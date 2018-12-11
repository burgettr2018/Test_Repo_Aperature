class AddPostponeAllInvitesToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :postpone_all_invites, :boolean, default: false, null: false
  end
end
