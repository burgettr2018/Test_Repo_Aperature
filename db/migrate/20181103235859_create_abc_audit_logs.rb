class CreateAbcAuditLogs < ActiveRecord::Migration
  def change
    create_table :abc_audit_logs do |t|
      t.string :message
      t.json :data
      t.string :log_type

      t.timestamps null: false
    end
  end
end
