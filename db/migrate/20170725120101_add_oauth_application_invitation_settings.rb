class AddOauthApplicationInvitationSettings < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :invitation_expiry_days, :integer
    add_column :users, :first_invitation_expires_at, :datetime
    add_column :users, :current_invitation_expires_at, :datetime
  end
end
