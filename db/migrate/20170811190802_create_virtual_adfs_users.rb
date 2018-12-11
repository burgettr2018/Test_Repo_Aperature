class CreateVirtualAdfsUsers < ActiveRecord::Migration
  def change
    create_table :rce_virtual_adfs_users do |t|
      t.references :user, null: false
      t.uuid :location_guid, null: false
      t.string :email, null: false
      t.string :username, null: false
      t.string :salt, null: false
      t.datetime :last_synced_to_adfs
      t.timestamps
    end
    add_index :rce_virtual_adfs_users, [:user_id, :location_guid], unique: true
    add_index :rce_virtual_adfs_users, :email, unique: true
    add_index :rce_virtual_adfs_users, :username, unique: true
    add_foreign_key :rce_virtual_adfs_users, :users
  end
end
