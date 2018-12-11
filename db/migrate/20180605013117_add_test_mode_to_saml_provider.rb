class AddTestModeToSamlProvider < ActiveRecord::Migration
  def change
    add_column :saml_identity_providers, :is_test_mode, :boolean
  end
end
