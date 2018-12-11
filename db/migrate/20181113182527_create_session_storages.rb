class CreateSessionStorages < ActiveRecord::Migration
  def change
    create_table :session_storages do |t|
      t.string :session_id
      t.string :name
      t.text :value

      t.timestamps null: false
    end

    add_index "session_storages", ["session_id", "name"], :name=>"session_storages_session_id_name", :unique=>true

  end
end
