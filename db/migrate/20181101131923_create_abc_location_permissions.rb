class CreateAbcLocationPermissions < ActiveRecord::Migration
  def change
    create_table :abc_location_permissions do |t|
      t.string :location_type
      t.string :location_number
      t.string :location
      t.string :email
      t.string :permission
      t.string :value

      t.timestamps null: false
    end
  end
end
