class AddInvitationStatusToUserApplications < ActiveRecord::Migration
  def change
    add_column :user_applications, :invitation_status, :string
  end
end
