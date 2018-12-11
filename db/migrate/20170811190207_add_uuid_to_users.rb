class AddUuidToUsers < ActiveRecord::Migration
  def change
    enable_extension 'uuid-ossp'
    add_column :users, :guid, :uuid, default: 'uuid_generate_v4()'
    User.update_all('guid = uuid_generate_v4()')
    change_column :users, :guid, :uuid, null: false
    add_index :users, :guid, unique: true
  end
end
