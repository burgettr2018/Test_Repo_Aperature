FactoryBot.define do
  factory :application_permission do
    transient do
      sequence(:application, 100) { |n| "SomeOtherApplication-#{n}" }
      sequence(:code, 100) { |n| "PERMISSION_#{n}" }
    end

    permission_type {create(:permission_type, application: application, code: code)}
    oauth_application
  end
end
