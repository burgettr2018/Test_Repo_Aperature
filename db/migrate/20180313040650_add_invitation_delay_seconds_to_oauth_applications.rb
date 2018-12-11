class AddInvitationDelaySecondsToOauthApplications < ActiveRecord::Migration
  def change
    add_column :oauth_applications, :invitation_delay_seconds, :integer
    cp = OauthApplication.find_by_name('CUSTOMER_PORTAL')
    cp.update_columns(invitation_delay_seconds: 3.minutes.to_i) if cp.present?
  end
end
