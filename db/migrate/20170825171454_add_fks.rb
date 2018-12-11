class AddFks < ActiveRecord::Migration
  def change

    ApplicationPermission.where(oauth_application_id: nil).delete_all
    ApplicationPermission.where.not(oauth_application_id: OauthApplication.all.pluck(:id)).delete_all
    change_column :application_permissions, :oauth_application_id, :integer, null: false
    add_foreign_key :application_permissions, :oauth_applications
    add_index :application_permissions, :oauth_application_id

    ApplicationPermission.where(permission_type_id: nil).delete_all
    ApplicationPermission.where.not(permission_type_id: PermissionType.all.pluck(:id)).delete_all
    change_column :application_permissions, :permission_type_id, :integer, null: false
    add_foreign_key :application_permissions, :permission_types
    add_index :application_permissions, :permission_type_id

    PermissionType.where(oauth_application_id: nil).delete_all
    PermissionType.where.not(oauth_application_id: OauthApplication.all.pluck(:id)).delete_all
    change_column :permission_types, :oauth_application_id, :integer, null: false
    add_foreign_key :permission_types, :oauth_applications
    # add_index :permission_types, :oauth_application_id  #already have 'permission_types_index' on id+code

    UserPermission.where(permission_type_id: nil).delete_all
    UserPermission.where.not(permission_type_id: PermissionType.all.pluck(:id)).delete_all
    change_column :user_permissions, :permission_type_id, :integer, null: false
    add_foreign_key :user_permissions, :permission_types
    add_index :user_permissions, :permission_type_id

    UserPermission.where(user_id: nil).delete_all
    UserPermission.where.not(user_id: User.all.pluck(:id)).delete_all
    change_column :user_permissions, :user_id, :integer, null: false
    add_foreign_key :user_permissions, :users
    add_index :user_permissions, :user_id

    UserApplication.where(user_id: nil).delete_all
    UserApplication.where.not(user_id: User.all.pluck(:id)).delete_all
    change_column :user_applications, :user_id, :integer, null: false
    add_foreign_key :user_applications, :users
    #add_index :user_applications, :user_id  #already have 'index_user_applications_on_user_id'

    UserApplication.where(oauth_application_id: nil).delete_all
    UserApplication.where.not(oauth_application_id: OauthApplication.all.pluck(:id)).delete_all
    change_column :user_applications, :oauth_application_id, :integer, null: false
    add_foreign_key :user_applications, :oauth_applications
    #add_index :user_applications, :oauth_application_id  #already have several including oauth_application_id

  end
end
