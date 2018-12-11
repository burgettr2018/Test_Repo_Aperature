# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20181103235859) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "abc_audit_logs", force: :cascade do |t|
    t.string   "message"
    t.json     "data"
    t.string   "log_type"
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "abc_location_permissions", force: :cascade do |t|
    t.string   "location_type"
    t.string   "location_number"
    t.string   "location"
    t.string   "email"
    t.string   "permission"
    t.string   "value"
    t.datetime "created_at",      :null=>false
    t.datetime "updated_at",      :null=>false
  end

  create_table "api_request_logs", force: :cascade do |t|
    t.datetime "time",                 :index=>{:name=>"index_api_request_logs_on_time"}
    t.string   "method",               :index=>{:name=>"index_api_request_logs_on_method"}
    t.string   "format"
    t.string   "url"
    t.string   "status",               :index=>{:name=>"index_api_request_logs_on_status"}
    t.string   "ip"
    t.string   "query_params"
    t.string   "raw_request_body"
    t.string   "parsed_request_body"
    t.string   "response"
    t.string   "trace_id"
    t.string   "access_token",         :index=>{:name=>"index_api_request_logs_on_access_token"}
    t.integer  "oauth_application_id", :null=>false, :index=>{:name=>"index_api_request_logs_on_oauth_application_id"}
    t.integer  "duration_ms"
    t.jsonb    "context_hash"
    t.string   "request_format"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.integer "access_token_id", :index=>{:name=>"index_api_tokens_on_access_token_id"}
    t.integer "user_id",         :index=>{:name=>"index_api_tokens_on_user_id"}
    t.string  "note",            :null=>false
  end

  create_table "application_permissions", force: :cascade do |t|
    t.integer  "oauth_application_id", :null=>false, :index=>{:name=>"index_application_permissions_on_oauth_application_id"}
    t.integer  "permission_type_id",   :null=>false, :index=>{:name=>"index_application_permissions_on_permission_type_id"}
    t.string   "value"
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
  end

  create_table "data_migrations", id: false, force: :cascade do |t|
    t.string "version", :null=>false, :index=>{:name=>"unique_data_migrations", :unique=>true}
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   :default=>0, :null=>false, :index=>{:name=>"delayed_jobs_priority", :with=>["run_at"]}
    t.integer  "attempts",   :default=>0, :null=>false
    t.text     "handler",    :null=>false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "devise_log_histories", force: :cascade do |t|
    t.integer  "user_id",       :index=>{:name=>"index_devise_log_histories_on_user_id"}
    t.string   "devise_action"
    t.datetime "date"
    t.string   "ip_address"
  end

  create_table "external_api_request_logs", force: :cascade do |t|
    t.datetime "time",                 :index=>{:name=>"index_external_api_request_logs_on_time"}
    t.string   "method",               :index=>{:name=>"index_external_api_request_logs_on_method"}
    t.string   "format"
    t.string   "url"
    t.string   "status",               :index=>{:name=>"index_external_api_request_logs_on_status"}
    t.jsonb    "request_headers"
    t.jsonb    "query_params"
    t.string   "request_body"
    t.jsonb    "response_headers"
    t.string   "response"
    t.string   "trace_id"
    t.string   "access_token"
    t.integer  "oauth_application_id", :null=>false, :index=>{:name=>"index_external_api_request_logs_on_oauth_application_id"}
    t.integer  "duration_ms",          :index=>{:name=>"index_external_api_request_logs_on_duration_ms"}
  end

  create_table "flipper_features", force: :cascade do |t|
    t.string   "key",        :null=>false, :index=>{:name=>"index_flipper_features_on_key", :unique=>true}
    t.datetime "created_at", :null=>false
    t.datetime "updated_at", :null=>false
  end

  create_table "flipper_gates", force: :cascade do |t|
    t.string   "feature_key", :null=>false, :index=>{:name=>"index_flipper_gates_on_feature_key_and_key_and_value", :with=>["key", "value"], :unique=>true}
    t.string   "key",         :null=>false
    t.string   "value"
    t.datetime "created_at",  :null=>false
    t.datetime "updated_at",  :null=>false
  end

  create_table "impersonation_logs", force: :cascade do |t|
    t.integer  "user_id",              :null=>false, :index=>{:name=>"index_impersonation_logs_on_user_id"}
    t.integer  "impersonated_user_id", :null=>false, :index=>{:name=>"index_impersonation_logs_on_impersonated_user_id"}
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "session_id"
  end

  create_table "maintenance_messages", force: :cascade do |t|
    t.integer  "oauth_application_id"
    t.datetime "start_date_utc"
    t.datetime "end_date_utc"
    t.string   "message"
    t.integer  "created_by_id",        :index=>{:name=>"index_maintenance_messages_on_created_by_id"}
  end

  create_table "oauth_access_grants", force: :cascade do |t|
    t.integer  "resource_owner_id", :null=>false
    t.integer  "application_id",    :null=>false
    t.string   "token",             :null=>false, :index=>{:name=>"index_oauth_access_grants_on_token", :unique=>true}
    t.integer  "expires_in",        :null=>false
    t.text     "redirect_uri",      :null=>false
    t.datetime "created_at",        :null=>false
    t.datetime "revoked_at"
    t.string   "scopes"
  end

  create_table "oauth_access_tokens", force: :cascade do |t|
    t.integer  "resource_owner_id", :index=>{:name=>"index_oauth_access_tokens_on_resource_owner_id"}
    t.integer  "application_id"
    t.string   "token",             :null=>false, :index=>{:name=>"index_oauth_access_tokens_on_token", :unique=>true}
    t.string   "refresh_token",     :index=>{:name=>"index_oauth_access_tokens_on_refresh_token", :unique=>true}
    t.integer  "expires_in"
    t.datetime "revoked_at"
    t.datetime "created_at",        :null=>false
    t.string   "scopes"
  end

  create_table "oauth_applications", force: :cascade do |t|
    t.string   "name",                     :null=>false
    t.string   "uid",                      :null=>false, :index=>{:name=>"index_oauth_applications_on_uid", :unique=>true}
    t.string   "secret",                   :null=>false
    t.text     "redirect_uri",             :null=>false
    t.string   "scopes",                   :default=>"", :null=>false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "application_uri"
    t.integer  "invitation_expiry_days"
    t.string   "saml_issuer",              :index=>{:name=>"index_oauth_applications_on_saml_issuer", :unique=>true}
    t.string   "saml_logout_url"
    t.string   "saml_acs",                 :index=>{:name=>"index_oauth_applications_on_saml_acs", :unique=>true}
    t.string   "proper_name"
    t.string   "sso_token",                :index=>{:name=>"index_oauth_applications_on_sso_token", :unique=>true}
    t.integer  "invitation_delay_seconds"
    t.string   "logout_url"
    t.boolean  "confidential",             :default=>true, :null=>false
    t.boolean  "postpone_all_invites",     :default=>false, :null=>false
  end

  create_table "permission_types", force: :cascade do |t|
    t.integer  "oauth_application_id", :null=>false, :index=>{:name=>"permission_types_index", :with=>["code"], :unique=>true}
    t.string   "code",                 :index=>{:name=>"permission_types_code_idx"}
    t.datetime "created_at",           :null=>false
    t.datetime "updated_at",           :null=>false
    t.string   "proper_name"
    t.boolean  "is_for_employees"
    t.boolean  "is_value_required"
  end
  add_index "permission_types", ["code"], :name=>"permission_types_code_idx1"
  add_index "permission_types", ["code"], :name=>"permission_types_code_idx2"
  add_index "permission_types", ["code"], :name=>"permission_types_code_idx3"

  create_table "rce_virtual_adfs_users", force: :cascade do |t|
    t.integer  "user_id",             :null=>false, :index=>{:name=>"index_rce_virtual_adfs_users_on_user_id_and_location_guid", :with=>["location_guid"], :unique=>true}
    t.uuid     "location_guid",       :null=>false
    t.string   "email",               :null=>false, :index=>{:name=>"index_rce_virtual_adfs_users_on_email", :unique=>true}
    t.string   "username",            :null=>false, :index=>{:name=>"index_rce_virtual_adfs_users_on_username", :unique=>true}
    t.string   "salt",                :null=>false
    t.datetime "last_synced_to_adfs"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "saml_identity_providers", force: :cascade do |t|
    t.string   "name",                   :index=>{:name=>"index_saml_identity_providers_on_name"}
    t.string   "token",                  :index=>{:name=>"index_saml_identity_providers_on_token"}
    t.string   "issuer"
    t.string   "idp_sso_target_url"
    t.string   "idp_cert"
    t.string   "idp_cert_fingerprint"
    t.string   "name_identifier_format"
    t.datetime "created_at",             :null=>false
    t.datetime "updated_at",             :null=>false
    t.boolean  "is_test_mode"
  end

  create_table "sso_redirects", force: :cascade do |t|
    t.integer "oauth_application_id", :index=>{:name=>"index_sso_redirects_on_oauth_application_id"}
    t.string  "token",                :null=>false
    t.string  "path",                 :null=>false
  end
  add_index "sso_redirects", ["oauth_application_id", "token"], :name=>"index_sso_redirects_on_oauth_application_id_and_token", :unique=>true

  create_table "sso_request_logs", force: :cascade do |t|
    t.datetime "time"
    t.integer  "oauth_application_id", :index=>{:name=>"index_sso_request_logs_on_oauth_application_id"}
    t.integer  "user_id",              :index=>{:name=>"index_sso_request_logs_on_user_id"}
    t.string   "access_token",         :index=>{:name=>"index_sso_request_logs_on_access_token"}
    t.jsonb    "params"
    t.string   "ip"
    t.string   "trace_id"
    t.boolean  "is_active"
    t.string   "message"
    t.boolean  "is_success",           :index=>{:name=>"index_sso_request_logs_on_is_success"}
  end

  create_table "user_applications", force: :cascade do |t|
    t.integer  "user_id",                    :null=>false, :index=>{:name=>"index_user_applications_on_user_id"}
    t.integer  "oauth_application_id",       :null=>false, :index=>{:name=>"index_user_applications_on_oauth_application_id"}
    t.string   "external_id",                :index=>{:name=>"index_user_applications_on_external_id"}
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "invitation_expires_in"
    t.datetime "first_invitation_sent_at"
    t.datetime "current_invitation_sent_at"
    t.integer  "invited_by_id",              :index=>{:name=>"index_user_applications_on_invited_by_id"}
    t.string   "invitation_token",           :index=>{:name=>"index_user_applications_on_invitation_token", :unique=>true}
    t.string   "invitation_status"
    t.boolean  "postpone_invite"
    t.integer  "assigned_to_id"
    t.integer  "form_submit_id"
    t.string   "request_status"
    t.string   "invitation_token_raw"
    t.boolean  "reminded"
    t.jsonb    "application_data"
  end
  add_index "user_applications", ["oauth_application_id", "external_id"], :name=>"index_user_applications_on_oauth_application_id_and_external_id", :unique=>true
  add_index "user_applications", ["user_id", "oauth_application_id"], :name=>"index_user_applications_on_user_id_and_oauth_application_id", :unique=>true

  create_table "user_email_validation_failures", force: :cascade do |t|
    t.datetime "start_date_utc"
    t.datetime "end_date_utc"
    t.string   "email"
    t.jsonb    "last_post_body"
    t.integer  "oauth_application_id", :index=>{:name=>"ix_user_email_fail_on_email_app", :with=>["email"], :unique=>true}
  end

  create_table "user_permissions", force: :cascade do |t|
    t.integer  "user_id",            :null=>false, :index=>{:name=>"index_user_permissions_on_user_id"}
    t.integer  "permission_type_id", :null=>false, :index=>{:name=>"index_user_permissions_on_permission_type_id"}
    t.string   "value"
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                    :default=>"", :null=>false, :index=>{:name=>"index_users_on_email", :unique=>true}
    t.string   "encrypted_password",       :default=>"", :null=>false
    t.string   "reset_password_token",     :index=>{:name=>"index_users_on_reset_password_token", :unique=>true}
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",            :default=>0, :null=>false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "confirmation_token",       :index=>{:name=>"index_users_on_confirmation_token", :unique=>true}
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.boolean  "admin"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "username",                 :index=>{:name=>"index_users_on_username", :unique=>true}
    t.boolean  "password_changed",         :default=>false
    t.integer  "failed_attempts",          :default=>0
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "last_password_change_at"
    t.string   "provider"
    t.string   "external_id",              :index=>{:name=>"index_users_on_external_id"}
    t.integer  "created_by_id",            :index=>{:name=>"index_users_on_created_by_id"}
    t.uuid     "guid",                     :default=>"uuid_generate_v4()", :null=>false, :index=>{:name=>"index_users_on_guid", :unique=>true}
    t.string   "last_application_context"
    t.boolean  "shared_mailbox"
    t.string   "preferred_language"
    t.jsonb    "provider_metadata"
  end

  add_foreign_key "api_request_logs", "oauth_applications"
  add_foreign_key "api_tokens", "oauth_access_tokens", column: "access_token_id"
  add_foreign_key "api_tokens", "users"
  add_foreign_key "application_permissions", "oauth_applications"
  add_foreign_key "application_permissions", "permission_types"
  add_foreign_key "devise_log_histories", "users"
  add_foreign_key "external_api_request_logs", "oauth_applications"
  add_foreign_key "maintenance_messages", "oauth_applications"
  add_foreign_key "maintenance_messages", "users", column: "created_by_id"
  add_foreign_key "oauth_access_grants", "oauth_applications", column: "application_id"
  add_foreign_key "oauth_access_tokens", "oauth_applications", column: "application_id"
  add_foreign_key "permission_types", "oauth_applications"
  add_foreign_key "rce_virtual_adfs_users", "users"
  add_foreign_key "sso_request_logs", "oauth_applications"
  add_foreign_key "sso_request_logs", "users"
  add_foreign_key "user_applications", "oauth_applications"
  add_foreign_key "user_applications", "users"
  add_foreign_key "user_applications", "users", column: "invited_by_id"
  add_foreign_key "user_email_validation_failures", "oauth_applications"
  add_foreign_key "user_permissions", "permission_types"
  add_foreign_key "user_permissions", "users"
  add_foreign_key "users", "users", column: "created_by_id"
end
