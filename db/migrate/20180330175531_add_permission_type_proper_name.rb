class AddPermissionTypeProperName < ActiveRecord::Migration
  def change
    add_column :permission_types, :proper_name, :string
		add_column :permission_types, :is_for_employees, :boolean
		add_column :permission_types, :is_value_required, :boolean
  end
end
