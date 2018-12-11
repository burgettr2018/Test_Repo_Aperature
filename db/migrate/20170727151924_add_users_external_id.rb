class AddUsersExternalId < ActiveRecord::Migration
  def change
    add_column :users, :external_id, :string
    add_index :users, :external_id
  end
end
