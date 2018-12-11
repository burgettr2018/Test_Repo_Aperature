class AddApplicationSpecificUidTable < ActiveRecord::Migration
  def change
    create_table :user_applications do |t|
      t.belongs_to :user, index: true
      t.belongs_to :oauth_application, index: true
      t.string :external_id, index: true
      t.timestamps
    end
    add_index :user_applications, [:user_id, :oauth_application_id], unique: true
    add_index :user_applications, [:oauth_application_id, :external_id], unique: true
  end
end
