class AddProviderMetadataBlobToUsers < ActiveRecord::Migration
  def change
    add_column :users, :provider_metadata, :jsonb
  end
end
