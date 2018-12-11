class AddUserEmailValidationFailures < ActiveRecord::Migration
  def change
    create_table :user_email_validation_failures do |t|
      t.datetime :start_date_utc
      t.datetime :end_date_utc
      t.string :email
      t.jsonb :last_post_body
      t.belongs_to :oauth_application
    end

    add_index :user_email_validation_failures, [:oauth_application_id, :email], unique: true, name: 'ix_user_email_fail_on_email_app'
    add_foreign_key :user_email_validation_failures, :oauth_applications
  end
end
