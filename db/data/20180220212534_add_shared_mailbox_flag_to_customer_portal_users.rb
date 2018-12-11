class AddSharedMailboxFlagToCustomerPortalUsers < ActiveRecord::Migration
  def self.up
    user_emails = %w(
                      proconnectexperts@owenscorning.com
                      oc.customerportal@owenscorning.com
                      processexcellence@owenscorning.com
                      crvmbox@owenscorning.com
                      servicioaclientesmexico@owenscorning.com
                  )

    User.where(email: user_emails).each do |user|
      user.shared_mailbox = true
      user.save!
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
