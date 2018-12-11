class AddMailboxToUsers < ActiveRecord::Migration
  def change
    add_column :users, :shared_mailbox, :boolean
  end
end
