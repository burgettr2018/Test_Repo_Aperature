class MoveInvitationFieldsToUserApplications < ActiveRecord::Migration
  def up
    add_column :user_applications, :invitation_expires_in, :integer
    add_column :user_applications, :first_invitation_sent_at, :datetime
    add_column :user_applications, :current_invitation_sent_at, :datetime
    add_column :user_applications, :invited_by_id, :integer
    add_index :user_applications, :invited_by_id
    add_foreign_key :user_applications, :users, column: :invited_by_id
    add_column :user_applications, :invitation_token, :string
    add_index :user_applications, :invitation_token, unique: true

    User.where.not(current_invitation_sent_at: nil).each do |u|
      application = u.user_applications.joins(:oauth_application).where.not(oauth_applications: {invitation_expiry_days: nil}).first
      if application.present?
        application.invitation_expires_in = u.invitation_expires_in
        application.first_invitation_sent_at = u.first_invitation_sent_at
        application.current_invitation_sent_at = u.current_invitation_sent_at
        application.invited_by_id = u.invited_by_id
        application.invitation_token = u.invitation_token
        application.save!
      end
    end

    remove_column :users, :invitation_expires_in
    remove_column :users, :first_invitation_sent_at
    remove_column :users, :current_invitation_sent_at
    remove_foreign_key :users, column: :invited_by_id
    remove_index :users, :invited_by_id
    remove_column :users, :invited_by_id
    remove_index :users, :invitation_token
    remove_column :users, :invitation_token
  end
  def down
    add_column :users, :invitation_expires_in, :integer
    add_column :users, :first_invitation_sent_at, :datetime
    add_column :users, :current_invitation_sent_at, :datetime
    add_column :users, :invited_by_id, :integer
    add_index :users, :invited_by_id
    add_foreign_key :users, :users, column: :invited_by_id
    add_column :users, :invitation_token, :string
    add_index :users, :invitation_token, unique: true

    User.joins(:user_applications).where.not(user_applications: {current_invitation_sent_at: nil}).each do |u|
      application = u.user_applications.where.not(current_invitation_sent_at: nil).first
      if application.present?
        u.invitation_expires_in = application.invitation_expires_in
        u.first_invitation_sent_at = application.first_invitation_sent_at
        u.current_invitation_sent_at = application.current_invitation_sent_at
        u.invited_by_id = application.invited_by_id
        u.invitation_token = application.invitation_token
        u.save!
      end
    end

    remove_column :user_applications, :invitation_expires_in
    remove_column :user_applications, :first_invitation_sent_at
    remove_column :user_applications, :current_invitation_sent_at
    remove_foreign_key :user_applications, column: :invited_by_id
    remove_index :user_applications, :invited_by_id
    remove_column :user_applications, :invited_by_id, :integer
    remove_index :user_applications, :invitation_token
    remove_column :user_applications, :invitation_token
  end
end
