class AddUserCreatedBySelfJoin < ActiveRecord::Migration
  def change
    add_column :users, :created_by_id, :integer
    add_column :users, :invited_by_id, :integer
    add_index :users, :created_by_id
    add_index :users, :invited_by_id

    add_foreign_key :users, :users, column: :created_by_id
    add_foreign_key :users, :users, column: :invited_by_id
  end
end
