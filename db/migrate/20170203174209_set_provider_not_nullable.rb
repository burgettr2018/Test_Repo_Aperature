class SetProviderNotNullable < ActiveRecord::Migration
  def change
    # need to do in a followup deploy since data_migration is not part of the standard deploy script
    #change_column :users, :provider, :string, :null => false
  end
end
