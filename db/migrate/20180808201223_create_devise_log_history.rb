class CreateDeviseLogHistory < ActiveRecord::Migration
  def change
    create_table :devise_log_histories do |t|
      t.references :user, index: true, foreign_key: true
      t.string :devise_action
      t.datetime :date
      t.string :ip_address
    end
  end
end
