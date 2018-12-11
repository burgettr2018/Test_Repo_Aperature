class AddLastApplicationContextToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_application_context, :string
  end
end
