class CreateUserPermissions < ActiveRecord::Migration
  def change

    create_table :user_permissions do |t|
      t.integer :user_id
      t.integer :permission_type_id
      t.string :value

      t.timestamps null: false
    end

    create_table :application_permissions do |t|
      t.integer :oauth_application_id
      t.integer :permission_type_id
      t.string :value

      t.timestamps null: false
    end

    create_table :permission_types do |t|
      t.integer :oauth_application_id
      t.string :code

      t.timestamps null: false
    end


    add_index :permission_types , [:oauth_application_id,:code],unique: true, :name => 'permission_types_index'
    # add_foreign_key :users,:user_permissions
    # add_foreign_key :oauth_applications,:user_permissions

  end
end
