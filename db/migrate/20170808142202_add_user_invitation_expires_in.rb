class AddUserInvitationExpiresIn < ActiveRecord::Migration
  def up
    add_column :users, :invitation_expires_in, :integer
    add_column :users, :first_invitation_sent_at, :datetime
    add_column :users, :current_invitation_sent_at, :datetime
    User.where.not(current_invitation_expires_at: nil).each do |u|
      application = u.user_applications.joins(:oauth_application).where.not(oauth_applications: {invitation_expiry_days: nil}).first
      if application.present?
        days = (application.oauth_application.invitation_expiry_days).days
        u.current_invitation_sent_at = u.read_attribute(:current_invitation_expires_at) - days
        u.first_invitation_sent_at = u.read_attribute(:first_invitation_expires_at) - days
        u.invitation_expires_in = days
        u.save!
      end
    end
    remove_column :users, :current_invitation_expires_at
    remove_column :users, :first_invitation_expires_at
  end
  def down
    add_column :users, :current_invitation_expires_at, :datetime
    add_column :users, :first_invitation_expires_at, :datetime
    User.where.not(current_invitation_sent_at: nil).each do |u|
      u.current_invitation_expires_at = u.current_invitation_sent_at + u.invitation_expires_in
      u.first_invitation_expires_at = u.first_invitation_sent_at + u.invitation_expires_in
      u.save!
    end
    remove_column :users, :invitation_expires_in, :integer
    remove_column :users, :first_invitation_sent_at, :datetime
    remove_column :users, :current_invitation_sent_at, :datetime
  end
end
