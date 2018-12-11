class AddApiTokens < ActiveRecord::Migration
  def change
    create_table :api_tokens do |t|
      t.references :access_token, index: true
      t.references :user, index: true
      t.string :note, null: false
    end
    add_foreign_key :api_tokens, :oauth_access_tokens, column: :access_token_id
    add_foreign_key :api_tokens, :users
  end
end
