class AddLastPasswordChangeAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_password_change_at, :datetime
  end
end
